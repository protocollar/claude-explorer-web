module ClaudeData
  # Resolves parent-child relationships between messages using parent_uuid.
  class MessageThreader
    def initialize(session)
      @session = session
    end

    def resolve_parent_references
      messages_by_uuid = @session.messages.index_by(&:uuid)

      @session.messages.where.not(parent_uuid: nil).find_each do |message|
        parent = messages_by_uuid[message.parent_uuid]
        if parent && message.parent_message_id != parent.id
          message.update!(parent_message: parent)
        end
      end
    end
  end
end
