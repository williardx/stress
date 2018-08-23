class Order < ApplicationRecord
  has_paper_trail
  SUPPORTED_CURRENCIES = %w[usd].freeze
  STATES = [
    PENDING = 'pending'.freeze,
    ABANDONED = 'abandoned'.freeze,
    # Check-out complete; payment authorized.
    # Buyer credit card has been authorized and hold has been placed.
    # At this point, availability must be confirmed manually.
    # Holds expire 7 days after being placed.
    SUBMITTED = 'submitted'.freeze,
    # Availability has been manually confirmed and hold has been "captured" (debited).
    APPROVED = 'approved'.freeze,
    # Items have been deemed unavailable and hold is voided.
    REJECTED = 'rejected'.freeze,

    FULFILLED = 'fulfilled'.freeze
  ].freeze

  STATE_EXPIRATIONS = {
    'pending' => 2.days,
    'submitted' => 2.days,
    'approved' => 5.days
  }.freeze

  FULFILLMENT_TYPES = [
    PICKUP = 'pickup'.freeze,
    SHIP = 'ship'.freeze
  ].freeze

  ACTIONS = %i[abandon submit approve reject fulfill].freeze

  has_many :line_items, dependent: :destroy, class_name: 'LineItem'
  has_many :transactions, dependent: :destroy

  validates :state, presence: true, inclusion: STATES

  after_create :set_code
  before_save :update_state_timestamps, if: :state_changed?
  before_save :set_currency_code

  scope :pending, -> { where(state: PENDING) }
  scope :active, -> { where(state: [SUBMITTED, APPROVED]) }

  ACTIONS.each do |action|
    define_method "#{action}!" do |&block|
      with_lock do
        state_machine.trigger!(action)
        save!
        block.call if block.present?
        self
      end
    rescue MicroMachine::InvalidState
      raise Errors::OrderError, "Invalid action on this #{state} order"
    end
  end

  def items_total_cents
    line_items.sum(:price_cents)
  end

  # Total amount (in cents) that the buyer will pay
  def buyer_total_cents
    items_total_cents + shipping_total_cents.to_i + tax_total_cents.to_i
  end

  # Total amount (in cents) that the seller will receive
  def seller_total_cents
    buyer_total_cents - commission_fee_cents.to_i - transaction_fee_cents.to_i
  end

  def shipping_info?
    fulfillment_type == PICKUP ||
      (fulfillment_type == SHIP && complete_shipping_details?)
  end

  def payment_info?
    credit_card_id.present?
  end

  def to_s
    "Order #{id}"
  end

  private

  def set_code
    update!(code: format('B%06d', id))
  end

  def update_state_timestamps
    self.state_updated_at = Time.now.utc
    send("#{state}_at=", Time.now.utc) unless state == Order::PENDING
    self.state_expires_at = STATE_EXPIRATIONS.key?(state) ? state_updated_at + STATE_EXPIRATIONS[state] : nil
  end

  def set_currency_code
    self.currency_code ||= 'usd'
  end

  def state_machine
    @state_machine ||= build_machine
  end

  def build_machine
    machine = MicroMachine.new(state)
    machine.when(:abandon, PENDING => ABANDONED)
    machine.when(:submit, PENDING => SUBMITTED)
    machine.when(:approve, SUBMITTED => APPROVED)
    machine.when(:reject, SUBMITTED => REJECTED)
    machine.when(:fulfill, APPROVED => FULFILLED)
    machine.on(:any) do
      self.state = machine.state
    end
    machine
  end

  def complete_shipping_details?
    [shipping_name, shipping_address_line1, shipping_city, shipping_country, shipping_postal_code].all?(&:present?)
  end
end
