require File.expand_path(File.dirname(__FILE__) + "/test_helper")

%w(hole mole muskrat kitty location comment difficulty unused_model).each do |a|
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
    Location.delete_all
    @location = Location.create(:name => "South wall")
    @hole.location = @location
    @hole.save!
    @mole = @hole.moles.create(:name => "Grabowski")
    
    # test has_one cardinality with model having a default scope
    Difficulty.unscoped.delete_all
    @hole_with_difficulty = Hole.create(:number => 16)
    @hole_with_difficulty.difficulty = Difficulty.create!(:name => 'Hard')
    @hole_with_difficulty.save!
    
    # test has_many cardinality with model having a default scope
    Comment.unscoped.delete_all
    @hole_with_comments = Hole.create(:number => 16)
    @hole_with_comments.comments << Comment.create!(:text => "Beware of the pond.")
    @hole_with_comments.comments << Comment.create!(:text => "Muskrats live here.")
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
  
  def test_dependent_permanent_records_with_has_many_cardinality_should_be_marked_as_deleted
    assert @hole.is_permanent?
    assert @hole.muskrats.first.is_permanent?
    assert_no_difference "Muskrat.count" do
      @hole.destroy
    end
    assert @hole.muskrats.first.deleted?
  end
  
  def test_dependent_permanent_records_with_has_one_cardinality_should_be_marked_as_deleted
    assert @hole.is_permanent?
    assert @hole.location.is_permanent?
    assert_no_difference "Location.count" do
      @hole.destroy
    end
    assert @hole.location.deleted?
    assert Location.find_by_name("South wall").deleted?
  end
  
  def test_dependent_permanent_records_with_has_many_cardinality_should_be_revived_when_parent_is_revived
    assert @hole.is_permanent?
    @hole.destroy
    assert @hole.muskrats.find_by_name("Active Muskrat").deleted?
    @hole.revive
    assert !@hole.muskrats.find_by_name("Active Muskrat").deleted?
  end
  
  def test_dependent_permanent_records_with_has_one_cardinality_should_be_revived_when_parent_is_revived
    assert @hole.is_permanent?
    @hole.destroy
    assert Location.find_by_name("South wall").deleted?
    @hole.revive
    assert !Location.find_by_name("South wall").deleted?
  end
  
  def test_dependent_permanent_records_with_has_one_cardinality_and_default_scope_should_be_revived_when_parent_is_revived
    assert @hole_with_difficulty.is_permanent?
    assert_difference("Difficulty.count", -1) do
      @hole_with_difficulty.destroy
    end
    assert_nil Difficulty.find_by_name("Hard")
    assert Difficulty.unscoped.find_by_name("Hard").deleted?
    @hole_with_difficulty.revive
    assert_not_nil Difficulty.find_by_name("Hard")
    assert !Difficulty.unscoped.find_by_name("Hard").deleted?
  end
  
  def test_dependent_permanent_records_with_has_many_cardinality_and_default_scope_should_be_revived_when_parent_is_revived
    assert @hole_with_comments.is_permanent?
    assert_difference("Comment.count", -2) do
      @hole_with_comments.destroy
    end
    assert_nil Comment.find_by_text("Beware of the pond.")
    assert Comment.unscoped.find_by_text("Beware of the pond.").deleted?
    @hole_with_comments.revive
    assert_not_nil Comment.find_by_text("Beware of the pond.")
    assert !Comment.unscoped.find_by_text("Beware of the pond.").deleted?
  end
  
  def test_inexistent_dependent_models_should_not_cause_errors
    hole_with_unused_model = Hole.create!(:number => 1)
    hole_with_unused_model.destroy
    assert_nothing_raised do
      hole_with_unused_model.revive
    end
  end
  
  def test_old_dependent_permanent_records_should_not_be_revived
    assert @hole.is_permanent?
    @hole.destroy
    assert @hole.muskrats.find_by_name("Deleted Muskrat").deleted?
    @hole.revive
    assert @hole.muskrats.find_by_name("Deleted Muskrat").deleted?
  end
  
  def test_validate_records_before_revival
    duplicate_location = Location.new(@location.attributes)
    @location.destroy
    @location.reload
    duplicate_location.save!
    assert_equal duplicate_location.name, @location.name
    assert_no_difference('Location.not_deleted.count') do
      assert_raise (ActiveRecord::RecordInvalid) do
        @location.revive
      end
    end
  end
  
  def test_force_deleting_a_record_with_has_one_force_deletes_dependent_records
    hole = Hole.create(:number => 1)
    location = Location.create(:name => "Near the clubhouse")
    hole.location = location
    hole.save!
    
    assert_difference('Hole.unscoped.count', -1) do
      assert_difference('Location.unscoped.count', -1) do
        hole.destroy(:force)
      end
    end
  end
  
  def test_force_deleting_a_record_with_has_many_force_deletes_dependent_records
    assert_difference('Hole.unscoped.count', -1) do
      assert_difference('Comment.unscoped.count', -2) do
        @hole_with_comments.destroy(:force)
      end
    end
  end
  
  def test_force_deletign_with_multiple_associations
    assert_difference('Muskrat.unscoped.count', -2) do
      assert_difference('Mole.unscoped.count', -1) do
        @hole.destroy(:force)
      end
    end
  end
end
