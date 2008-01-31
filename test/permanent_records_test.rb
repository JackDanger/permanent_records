require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/test_helper")
require File.expand_path(File.dirname(__FILE__) + "/muskrat")

class PermanentRecordsTest < Test::Unit::TestCase
  
  def setup
    super
    Muskrat.delete_all
    @wakko = Muskrat.create!(:name => 'Wakko')
    @yakko = Muskrat.create!(:name => 'Yakko', :deleted_at => 4.days.ago)
    @dot   = Muskrat.create!(:name => 'Dot')
    Kitty.delete_all
    @kitty = Kitty.create!(:name => 'Meow Meow')
  end
  
  def teardown
    setup
  end
  
  def test_destroy_should_return_the_record
    muskrat = @yakko
    assert_equal muskrat, muskrat.destroy
  end

  def test_destroy_should_set_deleted_at_attribute
    assert @yakko.destroy.deleted_at
  end
  
  def test_destroy_should_save_deleted_at_attribute
    assert Muskrat.find(@yakko.destroy.id).deleted_at
  end
  
  def test_destroy_should_freeze_record
    assert @yakko.destroy.frozen?
  end
  
  def test_destroy_should_not_really_remove_the_record
    assert Muskrat.find(@yakko.destroy.id)
  end
  
  def test_destroy_should_recognize_a_force_parameter
    assert_raises(ActiveRecord::RecordNotFound) { @yakko.destroy(:force).reload }
  end
  
  def test_destroy_should_ignore_other_parameters
    assert Muskrat.find(@yakko.destroy(:hula_dancer).id)
  end
  
  def test_revive_should_unfreeze_record
    assert !@wakko.revive.frozen?
  end
  
  def test_revive_should_unset_deleted_at
    assert !@wakko.revive.deleted_at
  end
  
  def test_revive_should_make_deleted_return_false
    assert !@wakko.revive.deleted?
  end
  
  def test_deleted_returns_true_for_deleted_records
    assert @yakko.deleted?
  end
  
  def test_with_deleted_limits_scope_to_deleted_records
    Muskrat.send :with_deleted do
      assert Muskrat.find(:all).all?(&:deleted?)
    end
  end
  
  def test_with_not_deleted_limits_scope_to_not_deleted_records
    Muskrat.send :with_not_deleted do
      assert !Muskrat.find(:all).any?(&:deleted?)
    end
  end
  
  def test_models_without_a_deleted_at_column_should_destroy_as_normal
    assert_raises(ActiveRecord::RecordNotFound) {@kitty.destroy.reload}
  end
end