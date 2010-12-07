require 'test/unit'
require 'net/sshr'
require 'net/sshr/result'
include Net::SSHR

class TestNetSSHR < Test::Unit::TestCase
  def test_exec
    # TODO: mock this, rather than requiring a localhost with whoami(1)
    sshr_exec(%w{localhost localhost localhost}, 'whoami') do |result|
      assert_not_nil result
      assert_kind_of Net::SSHR::Result, result
      assert_respond_to result, :stdout
      assert_respond_to result, :stderr
      assert_respond_to result, :exit_code
      assert_equal 'localhost', result.host
      assert_equal ENV['USER'], result.stdout.chomp!
      assert_equal '', result.stderr
      assert_equal 0, result.exit_code
    end
  end
  def test_nonblock_exec_single
    result_list = sshr_exec('root@localhost', 'whoami')
    assert_not_nil result_list
    assert_kind_of Array, result_list
    assert_kind_of Net::SSHR::Result, result_list[0]
    assert_equal 1, result_list.length
    assert_equal 0, result_list[0].exit_code
    assert_equal 'root', result_list[0].stdout.chomp!
  end
  def test_nonblock_exec
    result_list = sshr_exec(%w{root@localhost localhost}, 'whoami')
    assert_not_nil result_list
    assert_kind_of Array, result_list
    assert_kind_of Net::SSHR::Result, result_list[0]
    assert_equal 2, result_list.length
    assert_equal 0, result_list[0].exit_code
    assert_equal 'root', result_list[0].stdout.chomp!
    assert_equal ENV['USER'], result_list[1].stdout.chomp!
  end
end
