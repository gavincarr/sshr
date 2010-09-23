require 'test/unit'
require 'net/sshr/result'

class TestNetSSHRResult < Test::Unit::TestCase
  def test_good_constructor
    @res = Net::SSHR::Result.new('foo')
    assert_not_nil @res
    assert_equal @res.host, 'foo'
    assert_equal @res.stdout, ''
    assert_equal @res.stderr, ''
    assert_equal @res.exit_code, ''
  end
  def test_invalid_constructor
    assert_raise(ArgumentError, RuntimeError) { Net::SSHR::Result.new }
  end
  def test_accessors
    @res = Net::SSHR::Result.new('foo')
    @res.host = 'bar'
    @res.stdout = 'Hello World!'
    @res.stderr = 'Error: core dump'
    @res.exit_code = 1
    assert_equal @res.host, 'bar'
    assert_equal @res.stdout, 'Hello World!'
    assert_equal @res.stderr, 'Error: core dump'
    assert_equal @res.exit_code, 1
  end
  def test_append_methods
    @res = Net::SSHR::Result.new('foo')
    @res.stdout = 'Hello';
    @res.append_stdout(' World!');
    @res.append_stderr('Error:');
    @res.append_stderr(' core dump');
    assert_equal @res.stdout, 'Hello World!'
    assert_equal @res.stderr, 'Error: core dump'
  end
end

