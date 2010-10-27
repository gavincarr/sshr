require 'test/unit'
require 'net/sshr'
require 'net/sshr/result'
include Net::SSHR

class TestNetSSHR < Test::Unit::TestCase
  def test_exec
    # TODO: mock this, rather than requiring a localhost with date(1)
    sshr_exec(%w{localhost localhost localhost}, 'date') do |result|
      assert_not_nil result
      assert_kind_of Net::SSHR::Result, result
      assert_respond_to result, :stdout
      assert_respond_to result, :stderr
      assert_respond_to result, :exit_code
      assert_equal 'localhost', result.host
      assert_match /^\w{3}\s+\w{3}\s+\d+/, result.stdout
      assert_equal '', result.stderr
      assert_equal 0, result.exit_code
    end
  end
  def test_nonblock_exec
    result = sshr_exec('localhost', 'date')
    assert_not_nil result
    assert_kind_of Net::SSHR::Result, result
    assert_equal 0, result.exit_code
    assert_match /^\w{3}\s+\w{3}\s+\d+/, "#{result}"
  end
end

