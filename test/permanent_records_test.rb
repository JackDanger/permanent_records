require File.expand_path(File.dirname(__FILE__) + "/test_helper")

%w(hole mole muskrat kitty).each do |a|
  require File.expand_path(File.dirname(__FILE__) + "/" + a)
end

class PermanentRecordsTest < ActiveSupport::TestCase
  
  def setup
    super
    Muskrat.delete_all
    @active = Muskrat.create!(:name => 'Wakko')
    @deleted = Muskrat.create!(:name => 'Yakko', :deleted_at => 4.days.ago)
    @the_girl   = Muskrat.create!(:name => 'Dot')
    Kitty.delete_all
    @kitty = Kitty.create!(:name => 'Meow Meow')
    @hole = Hole.create(:number => 14)
    @hole.muskrats.create(:name => "Active Muskrat")
    @hole.muskrats.create(:name => "Deleted Muskrat", :deleted_at => 5.days.ago)
    @mole = @hole.moles.create(:name => "Grabowski")
  end
  
  def teardown
    setup
  end
  
  def test_destroy_should_return_the_record
    muskrat = @active
    assert_equal muskrat, muskrat.destroy
  end
  
  def test_revive_should_return_the_record
    muskrat = @deleted
    assert_equal muskrat, muskrat.revive
  end

  def test_destroy_should_set_deleted_at_attribute
    assert @active.destroy.deleted_at
  end
  
  def test_destroy_should_save_deleted_at_attribute
    assert Muskrat.find(@active.destroy.id).deleted_at
  end
  
  def test_destroy_should_not_really_remove_the_record
    assert Muskrat.find(@active.destroy.id)
  end
  
  def test_destroy_should_recognize_a_force_parameter
    assert_raises(ActiveRecord::RecordNotFound) { @active.destroy(:force).reload }
  end
  
  def test_destroy_should_ignore_other_parameters
    assert Muskrat.find(@active.destroy(:hula_dancer).id)
  end
  
  def test_revive_should_unfreeze_record
    assert !@deleted.revive.frozen?
  end
  
  def test_revive_should_unset_deleted_at
    assert !@deleted.revive.deleted_at
  end
  
  def test_revive_should_make_deleted_return_false
    assert !@deleted.revive.deleted?
  end
  
  def test_deleted_returns_true_for_deleted_records
    assert @deleted.deleted?
  end
  
  def test_destroy_returns_record_with_modified_attributes
    assert @active.destroy.deleted?
  end
  
  def test_revive_and_destroy_should_be_chainable
    assert @active.destroy.revive.destroy.destroy.revive.revive.destroy.deleted?
    assert !@deleted.destroy.revive.revive.destroy.destroy.revive.deleted?
  end
  
  def test_with_counting_on_deleted_limits_scope_to_count_deleted_records
    assert_equal Muskrat.deleted.length,
                 Muskrat.deleted.count
  end

  def test_with_counting_on_not_deleted_limits_scope_to_count_not_deleted_records
    assert_equal Muskrat.not_deleted.length,
                 Muskrat.not_deleted.count
  end

  def test_with_deleted_limits_scope_to_deleted_records
    assert Muskrat.deleted.all?(&:deleted?)
  end
  
  def test_with_not_deleted_limits_scope_to_not_deleted_records
    assert !Muskrat.not_deleted.any?(&:deleted?)
  end
  
  def test_models_without_a_deleted_at_column_should_destroy_as_normal
    assert_raises(ActiveRecord::RecordNotFound) {@kitty.destroy.reload}
  end
  
  def test_dependent_non_permanent_records_should_be_destroyed
    assert @hole.is_permanent?
    assert !@hole.moles.first.is_permanent?
    assert_difference "Mole.count", -1 do
      @hole.destroy
    end
  end
  
  def test_dependent_permanent_records_should_be_marked_as_deleted
    assert @hole.is_permanent?
    assert @hole.muskrats.first.is_permanent?
    assert_no_difference "Muskrat.count" do
      @hole.destroy
    end
    assert @hole.muskrats.first.deleted?
  end
  
  def test_dependent_permanent_records_should_be_revived_when_parent_is_revived
    assert @hole.is_permanent?
    @hole.destroy
    assert @hole.muskrats.find_by_name("Active Muskrat").deleted?
    @hole.revive
    assert !@hole.muskrats.find_by_name("Active Muskrat").deleted?
  end
  
  def test_old_dependent_permanent_records_should_not_be_revived
    assert @hole.is_permanent?
    @hole.destroy
    assert @hole.muskrats.find_by_name("Deleted Muskrat").deleted?
    @hole.revive
    assert @hole.muskrats.find_by_name("Deleted Muskrat").deleted?
  end
  
  def ensure_before_destroy_callback_still_works
    assert_false @hole.saw_about_to_destroy
    @hole.destroy
    assert @hole.saw_about_to_destroy
  end
  
  def ensure_after_destroy_callback_still_works
    assert_false @hole.saw_after_destroy
    @hole.destroy
    assert @hole.saw_after_destroy
  end
end
