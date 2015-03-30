require_relative '../helper'
require 'fluent/plugin/filter_string_irc_slack'
require 'string-irc'

class StringIrcSlackFilterTest < Test::Unit::TestCase
  include Fluent

  setup do
    Fluent::Test.setup
    @time = Fluent::Engine.now
  end

  def create_driver(conf = '')
    Test::FilterTestDriver.new(StringIrcSlackFilter).configure(conf, true)
  end

  def filter(config, msgs)
    d = create_driver(config)
    d.run {
      msgs.each {|msg|
        d.filter(msg, @time)
      }
    }
    filtered = d.filtered_as_array
    filtered.map {|m| m[2] }
  end

  sub_test_case 'configure' do
    test 'check default' do
      assert_nothing_raised { create_driver }
    end
  end

  def test_filter
    si1 = StringIrc.new('hello').red.underline.to_s
    si2 = StringIrc.new('world').yellow('green').bold.to_s
    message = "#{si1} #{si2}"
    msgs = [{"message" => message}]
    filtered = filter('', msgs)
    assert_equal([{"message" => "`hello` `world`"}], filtered)
  end

  def test_invalid_byte_sequence
    invalid_string = "\xff".force_encoding('UTF-8')
    msgs = [{"message" => invalid_string}]
    filtered = filter('', msgs)
    assert_equal([{"message" => "?"}], filtered)
  end
end
