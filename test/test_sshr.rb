# sshr tests

require 'test/unit'

class TestSSHR < Test::Unit::TestCase
  def setup
    @dir = File.join(Dir.getwd, File.dirname($0))
    @sshr = File.join(@dir, '..', 'bin', 'sshr')
  end

  def test_long
    outerr = "[localhost]\nOutput the first\nOutput the second\nOutput the third\n\nError the first\nError the second\nError the third\n\n"
    out = "[localhost]\nOutput the first\nOutput the second\nOutput the third\n\n"
    err = "[localhost]\nError the first\nError the second\nError the third\n\n"

    cmd = "#{@sshr} --long localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal outerr, io.gets(nil) }

    cmd = "#{@sshr} -l -b localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal outerr, io.gets(nil) }

    cmd = "#{@sshr} --long -o localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal out, io.gets(nil) }

    cmd = "#{@sshr} -l -e localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal err, io.gets(nil) }

    cmd = "#{@sshr} --long -x localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal out, io.gets(nil) }
  end

  def test_short
    outerr = "localhost:           Output the first\nlocalhost:           Error the first\n"
    out = "localhost:           Output the first\n"
    err = "localhost:           Error the first\n"
    user = "localhost:           #{ENV['USER']}\n"
    root = "localhost:           root\n"

    cmd = "#{@sshr} --short localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal out, io.gets(nil) }

    cmd = "#{@sshr} -s -b localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal outerr, io.gets(nil) }

    cmd = "#{@sshr} --short -o localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal out, io.gets(nil) }

    cmd = "#{@sshr} -s -e localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal err, io.gets(nil) }

    cmd = "#{@sshr} --short -x localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal out, io.gets(nil) }

    # TODO: figure out how to mock this instead of requiring root ssh and whoami
    cmd = "#{@sshr} localhost whoami"
    IO.popen(cmd) { |io| assert_equal user, io.gets(nil) }

    cmd = "#{@sshr} --user root localhost whoami"
    IO.popen(cmd) { |io| assert_equal root, io.gets(nil) }
  end

  def test_json
    json = "{\"stdout\":\"Output the first\\nOutput the second\\nOutput the third\",\"user\":\"\",\"json_class\":\"Net::SSHR::Result\",\"stderr\":\"Error the first\\nError the second\\nError the third\",\"exit_code\":0,\"cmd\":\"/export/home/gavin/work/sshr/test/helper_test_cmd.rb\",\"host\":\"localhost\",\"host_string\":\"localhost\"}\n"

    cmd = "#{@sshr} --json localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal json, io.gets(nil) }

    cmd = "#{@sshr} -j localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal json, io.gets(nil) }
  end
end

