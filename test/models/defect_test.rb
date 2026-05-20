require "test_helper"

class DefectTest < ActiveSupport::TestCase
  setup do
    @defect = defects(:leaking_sink)
  end

  test "open scope excludes signed-off and closed" do
    assert_includes Defect.open, @defect
    @defect.update!(status: :signed_off)
    assert_not_includes Defect.open, @defect
  end

  test "sla_state classifies green/amber/red" do
    @defect.update!(sla_target_date: 10.days.from_now)
    assert_equal :green, @defect.sla_state
    @defect.update!(sla_target_date: 1.day.from_now)
    assert_equal :amber, @defect.sla_state
    @defect.update!(sla_target_date: 2.days.ago)
    assert_equal :red, @defect.sla_state
  end

  test "for scope only returns the given organization" do
    other_org = Organization.create!(name: "Other", slug: "other-test")
    assert_equal 1, Defect.for(organizations(:acme)).count
    assert_equal 0, Defect.for(other_org).count
  end

  test "contractor_token and resident_signoff_token are valid signed ids" do
    ct = @defect.contractor_token
    rt = @defect.resident_signoff_token
    assert_equal @defect, Defect.find_signed!(ct, purpose: :contractor)
    assert_equal @defect, Defect.find_signed!(rt, purpose: :resident_signoff)
    # wrong purpose raises
    assert_raises(ActiveSupport::MessageVerifier::InvalidSignature) do
      Defect.find_signed!(ct, purpose: :resident_signoff)
    end
  end
end
