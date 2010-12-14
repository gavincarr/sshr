# sshr tests

require 'test/unit'
require 'open3'

class TestSSHR < Test::Unit::TestCase
  def setup
    @dir = File.join(Dir.getwd, File.dirname($0))
    @sshr = File.join(@dir, '..', 'bin', 'sshr')
  end
  def test_option_conflicts
    format_conflict = %r{^Error: only one format option may be specified}
    outerr_conflict = %r{^Error: only one stdout/stderr option may be specified}

    cmd = "#{@sshr} --long --short localhost whoami"
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      assert_equal(nil, stdout.gets(nil))
      assert_match(format_conflict, stderr.gets(nil))
    end

    cmd = "#{@sshr} --short --list localhost whoami"
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      assert_equal(nil, stdout.gets(nil))
      assert_match(format_conflict, stderr.gets(nil))
    end

    cmd = "#{@sshr} --out --stderr localhost whoami"
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      assert_equal(nil, stdout.gets(nil))
      assert_match(outerr_conflict, stderr.gets(nil))
    end

    cmd = "#{@sshr} --oex --oeb localhost whoami"
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      assert_equal(nil, stdout.gets(nil))
      assert_match(outerr_conflict, stderr.gets(nil))
    end
  end
end

