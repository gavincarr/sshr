require 'test/unit'
require 'net/sshr'
require 'net/sshr/result'
include Net::SSHR

class TestNetSSHR < Test::Unit::TestCase
  def test_exec
    # TODO: mock this, rather than requiring a localhost with date(1)
    sshr_exec_list([ 
                     [ 'dns1', 'hostname' ],
                     [ 'dns2', 'uname -r' ],
                     [ 'dns3', 'date' ],
                   ], { :verbose => 1 }) do |result|
      assert_not_nil result
      assert_kind_of Net::SSHR::Result, result
      assert_respond_to result, :stdout
      assert_respond_to result, :stderr
      assert_respond_to result, :exit_code
      assert_match /^dns/, result.host
      assert_not_nil result.stdout
      assert_equal '', result.stderr
      assert_equal 0, result.exit_code
    end
  end
end

