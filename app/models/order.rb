class Order < ApplicationRecord
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

    FINALIZED = 'finalized'.freeze
  ].freeze

  ACTIONS = %i[abandon submit approve reject finalize].freeze

  has_many :line_items, dependent: :destroy, class_name: 'LineItem'
  has_many :history, dependent: :destroy, class_name: 'OrderHistory'

  validates :state, presence: true, inclusion: STATES

  before_create :set_code
  before_save :set_currency_code

  scope :pending, -> { where(state: PENDING) }

  ACTIONS.each do |action|
    define_method "#{action}!" do
      state_machine.trigger!(action)
    rescue MicroMachine::InvalidState
      raise Errors::OrderError, "Invalid action on this #{state} order"
    end
  end

  def items_total_cents
    (line_items.present? && line_items.map(&:price_cents).reduce(0, :+)) || 0
  end

  private

  def set_code
    self.code = SecureRandom.hex(10)
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
    machine.when(:finalize, APPROVED => FINALIZED)
    machine.on(:any) do
      self.state = machine.state
    end
    machine
  end
end
