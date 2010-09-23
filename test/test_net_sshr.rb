require 'test/unit'
require 'net/sshr'
require 'net/sshr/result'

class TestNetSSHR < Test::Unit::TestCase
  def test_good_constructor
    @sshr = Net::SSHR.new( :hosts => [ 'foo', 'bar' ] )
    assert_not_nil @sshr
    assert_equal @sshr.hosts, [ 'foo', 'bar' ]
  end
  def test_invalid_constructor
    assert_raise(ArgumentError, RuntimeError) { Net::SSHR.new }
    assert_raise(ArgumentError, RuntimeError) { Net::SSHR.new( :foo => 1 ) }
  end
  def test_good_exec
    # TODO: mock this, rather than requiring a localhost with date(1)
    @sshr = Net::SSHR.new( :hosts => 'localhost' )
    assert_not_nil @sshr
    @sshr.exec('date') do |result|
      assert_not_nil result
      assert_kind_of Net::SSHR::Result, result
      assert_respond_to result, :stdout
      assert_respond_to result, :stderr
      assert_respond_to result, :exit_code
      assert_equal 'localhost', result.host
      assert_match /^\w{3} \w{3} \d+/, result.stdout
      assert_equal '', result.stderr
      assert_equal 0, result.exit_code
    end
  end
end

