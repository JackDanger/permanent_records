require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/test_helper")
require File.expand_path(File.dirname(__FILE__) + "/leprechaun")

class CachedValuesTest < Test::Unit::TestCase
  
  def setup
    @mc_nairn = Leprechaun.find(:first)
    @mc_nairn.favorite_color_in_rot_13.clear
    @mc_nairn.favorite_color_turned_uppercase.clear
    @mc_nairn.id_of_first_leprechaun_with_same_favorite_color.clear
    @mc_nairn.favorite_color_in_rot_13_without_cache.clear
    @mc_nairn.favorite_color_turned_uppercase_with_explicit_cache.clear
    @mc_nairn.favorite_color = 'blue'
    @mc_nairn.save!
  end
  
  def teardown
    setup
  end
  
  def test_proc_should_properly_calculate_value
    assert_equal 'blue', @mc_nairn.favorite_color
    assert_equal 'oyhr', @mc_nairn.favorite_color.tr("A-Za-z", "N-ZA-Mn-za-m")
    assert_equal 'oyhr', @mc_nairn.favorite_color_in_rot_13
  end
  
  def test_string_should_properly_calculate_value
    assert_equal 'blue', @mc_nairn.favorite_color
    assert_equal 'BLUE', @mc_nairn.favorite_color_turned_uppercase
    @mc_nairn.update_attribute(:favorite_color, 'gold')
    assert_equal 'BLUE', @mc_nairn.favorite_color_turned_uppercase
    assert_equal 'GOLD', @mc_nairn.favorite_color_turned_uppercase.reload
  end
  
  def test_symbol_should_calculate_value_from_method_call
    assert_equal '127 gold coins', @mc_nairn.number_of_gold_coins
    assert_equal '127 gold coins', @mc_nairn.calculate_gold
    @mc_nairn.class.class_eval { def calculate_gold; '255 gold coins'; end }
    assert_equal '255 gold coins', @mc_nairn.calculate_gold
    assert_equal '127 gold coins', @mc_nairn.number_of_gold_coins
    assert_equal '255 gold coins', @mc_nairn.number_of_gold_coins.reload
  end
  
  def test_sql_should_properly_calculate_value
    assert_equal 3, @mc_nairn.id_of_first_leprechaun_with_same_favorite_color
    Leprechaun.find_by_name("O' Houhlihan").update_attribute(:favorite_color, 'blue')
    assert_equal 3, @mc_nairn.id_of_first_leprechaun_with_same_favorite_color
    assert_equal 2, @mc_nairn.id_of_first_leprechaun_with_same_favorite_color.reload
  end
  
  def test_should_cache_value
    assert_equal 'blue', @mc_nairn.favorite_color
    assert_equal 'oyhr', @mc_nairn.favorite_color_in_rot_13
    @mc_nairn.update_attribute(:favorite_color, 'red')
    assert_equal 'erq', @mc_nairn.favorite_color.tr("A-Za-z", "N-ZA-Mn-za-m")
    assert_equal 'oyhr', @mc_nairn.favorite_color_in_rot_13
  end

  def test_cache_should_be_invalidated_on_clear
    assert_equal 'blue', @mc_nairn.favorite_color
    assert_equal 'oyhr', @mc_nairn.favorite_color_in_rot_13
    @mc_nairn.favorite_color_in_rot_13.clear
    assert_nil @mc_nairn.send(:read_attribute, :favorite_color_in_rot_13)
  end
  
  def test_value_should_be_updated_after_its_cleared
    assert_equal 'blue', @mc_nairn.favorite_color
    assert_equal 'oyhr', @mc_nairn.favorite_color_in_rot_13
    @mc_nairn.update_attribute(:favorite_color, 'red')
    assert_equal 'oyhr', @mc_nairn.favorite_color_in_rot_13
    @mc_nairn.favorite_color_in_rot_13.clear    
    assert_equal 'erq', @mc_nairn.favorite_color_in_rot_13
  end
  
  def test_should_not_cache_explicitly_noncaching_values
    assert_equal 'blue', @mc_nairn.favorite_color
    assert_equal 'oyhr', @mc_nairn.favorite_color_in_rot_13_without_cache
    assert_nil @mc_nairn.send(:read_attribute, :favorite_color_in_rot_13_without_cache)
    @mc_nairn.update_attribute(:favorite_color, 'red')
    assert_equal 'erq', @mc_nairn.favorite_color.tr("A-Za-z", "N-ZA-Mn-za-m")
    assert_equal 'erq', @mc_nairn.favorite_color_in_rot_13_without_cache.reload
    assert_nil @mc_nairn.send(:read_attribute, :favorite_color_in_rot_13_without_cache)
  end
  
  def test_should_respect_explicit_cache_column
    assert_equal 'BLUE', @mc_nairn.favorite_color_turned_uppercase_with_explicit_cache
    assert_equal 'BLUE', @mc_nairn.send(:read_attribute, :some_other_cache_field)
    @mc_nairn.update_attribute(:favorite_color, 'red')
    assert_equal 'BLUE', @mc_nairn.send(:read_attribute, :some_other_cache_field)
    assert_equal 'RED', @mc_nairn.favorite_color_turned_uppercase_with_explicit_cache.reload
  end
  
  def test_reload_callback_should_fire
    value = @mc_nairn.reload_callback.to_s
    assert_equal value.to_i, @mc_nairn.reload_callback
    @mc_nairn.save!
    assert_not_equal value.to_i, @mc_nairn.reload_callback.reload
    value = @mc_nairn.reload_callback.to_s
    assert_equal value.to_i, @mc_nairn.reload_callback
    @mc_nairn.valid?
    assert_not_equal value.to_i, @mc_nairn.reload_callback
  end
  
  def test_clear_callback_should_fire
    assert @mc_nairn.clear_callback
    assert @mc_nairn.instance_variable_get("@clear_callback")
    @mc_nairn.valid?
    assert_nil @mc_nairn.instance_variable_get("@clear_callback")
  end
  
  def test_sql_should_cast_to_integer
    assert @mc_nairn.integer_cast.is_a?(Fixnum)
  end
  
  def test_sql_should_cast_to_string
    assert @mc_nairn.string_cast.is_a?(String)
  end
  
  def test_sql_should_cast_to_float
    assert @mc_nairn.float_cast.is_a?(Float)
  end
end