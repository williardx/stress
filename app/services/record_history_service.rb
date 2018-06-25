module RecordHistoryService
  def self.create!(record, modifier_id, args)
    record.history.create!(
      changed_fields: args,
      modifier_id: modifier_id
    )
  end
end
