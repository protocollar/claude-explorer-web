require "test_helper"

module ClaudeData
  class MessageThreaderTest < ActiveSupport::TestCase
    setup do
      @project_session = project_sessions(:main_session)
      @threader = MessageThreader.new(@project_session)
    end

    test "links child message to parent by uuid" do
      # Create unlinked messages
      parent = @project_session.messages.create!(
        uuid: "threader-parent-uuid",
        message_type: "user",
        role: "user",
        content: [],
        timestamp: 1.hour.ago
      )

      child = @project_session.messages.create!(
        uuid: "threader-child-uuid",
        parent_uuid: "threader-parent-uuid",
        message_type: "assistant",
        role: "assistant",
        content: [],
        timestamp: 59.minutes.ago
      )

      assert_nil child.parent_message_id

      @threader.resolve_parent_references

      assert_equal parent, child.reload.parent_message
    end

    test "ignores messages without parent_uuid" do
      root = @project_session.messages.create!(
        uuid: "threader-root-uuid",
        parent_uuid: nil,
        message_type: "user",
        role: "user",
        content: [],
        timestamp: 1.hour.ago
      )

      @threader.resolve_parent_references

      assert_nil root.reload.parent_message
    end

    test "handles missing parent gracefully" do
      orphan = @project_session.messages.create!(
        uuid: "threader-orphan-uuid",
        parent_uuid: "nonexistent-uuid",
        message_type: "assistant",
        role: "assistant",
        content: [],
        timestamp: 1.hour.ago
      )

      assert_nothing_raised do
        @threader.resolve_parent_references
      end

      assert_nil orphan.reload.parent_message
    end

    test "skips messages that are already linked correctly" do
      # Use existing fixture messages that are already linked
      existing = messages(:assistant_response)
      original_parent = existing.parent_message

      @threader.resolve_parent_references

      assert_equal original_parent, existing.reload.parent_message
    end

    test "processes all messages in session with parent_uuid" do
      parent1 = @project_session.messages.create!(
        uuid: "batch-parent-1",
        message_type: "user",
        role: "user",
        content: [],
        timestamp: 2.hours.ago
      )

      child1 = @project_session.messages.create!(
        uuid: "batch-child-1",
        parent_uuid: "batch-parent-1",
        message_type: "assistant",
        role: "assistant",
        content: [],
        timestamp: 1.hour.ago
      )

      parent2 = @project_session.messages.create!(
        uuid: "batch-parent-2",
        message_type: "user",
        role: "user",
        content: [],
        timestamp: 50.minutes.ago
      )

      child2 = @project_session.messages.create!(
        uuid: "batch-child-2",
        parent_uuid: "batch-parent-2",
        message_type: "assistant",
        role: "assistant",
        content: [],
        timestamp: 45.minutes.ago
      )

      @threader.resolve_parent_references

      assert_equal parent1, child1.reload.parent_message
      assert_equal parent2, child2.reload.parent_message
    end
  end
end
