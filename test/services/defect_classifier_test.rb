require "test_helper"

class DefectClassifierTest < ActiveSupport::TestCase
  setup { @org = organizations(:acme) }

  test "detects plumbing + high from a leak phrase" do
    s = DefectClassifier.suggest("Leak under kitchen sink, water on floor", organization: @org)
    assert_equal "Plumbing", s[:trade_name]
    assert_equal "high",     s[:priority]
    assert_includes s[:matched_keywords], "leak"
  end

  test "detects electrical from a flickering light" do
    s = DefectClassifier.suggest("Hallway light flickering on and off", organization: @org)
    assert_equal "Electrical", s[:trade_name]
    # flickering is a safety signal — classifier escalates to high priority
    assert_includes %w[high medium], s[:priority]
  end

  test "detects urgent for a gas leak" do
    s = DefectClassifier.suggest("Strong smell of gas in the kitchen", organization: @org)
    assert_equal "urgent", s[:priority]
  end

  test "returns nil trade when no keywords match" do
    s = DefectClassifier.suggest("everything is fine actually", organization: @org)
    assert_nil s[:trade_name]
  end

  test "wraps trade_id when the org has the matching trade" do
    s = DefectClassifier.suggest("Pipe leak under bathroom sink", organization: @org)
    assert_equal trades(:plumbing).id, s[:trade_id]
  end
end
