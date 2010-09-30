require 'test/unit'
require 'net/sshr/result'

class TestNetSSHRResult < Test::Unit::TestCase
  def test_good_constructor
    @res = Net::SSHR::Result.new('foo', 'ls -l')
    assert_not_nil @res
    assert_equal 'foo', @res.host
    assert_equal 'ls -l', @res.cmd
    assert_equal '', @res.stdout
    assert_equal '', @res.stderr
    assert_equal nil, @res.exit_code
  end
  def test_invalid_constructor
    assert_raise(ArgumentError, RuntimeError) { Net::SSHR::Result.new }
  end
  def test_accessors
    @res = Net::SSHR::Result.new('bar', 'ls -l')
    @res.host = 'bar'
    @res.cmd = 'ls -l'
    @res.stdout = 'Hello World!'
    @res.stderr = 'Error: core dump'
    @res.exit_code = 1
    assert_equal 'bar', @res.host
    assert_equal 'Hello World!', @res.stdout
    assert_equal 'Error: core dump', @res.stderr
    assert_equal 1, @res.exit_code
  end
  def test_appending
    @res = Net::SSHR::Result.new('foo', 'ls -l')
    @res.stdout = 'Hello';
    @res.stdout << ' World!';
    @res.stderr << 'Error:';
    @res.stderr << ' core dump';
    assert_equal 'Hello World!', @res.stdout
    assert_equal 'Error: core dump', @res.stderr
  end
end

