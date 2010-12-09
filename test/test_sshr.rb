# sshr tests

require 'test/unit'

class TestSSHR < Test::Unit::TestCase
  def setup
    @dir = File.join(Dir.getwd, File.dirname($0))
    @sshr = File.join(@dir, '..', 'bin', 'sshr')
  end

  def test_long
    outerr      = "[localhost]\nOutput the first\nOutput the second\nOutput the third\n\nError the first\nError the second\nError the third\n"
    out         = "[localhost]\nOutput the first\nOutput the second\nOutput the third\n"
    err         = "[localhost]\nError the first\nError the second\nError the third\n"
    outerr_nh   = "Output the first\nOutput the second\nOutput the third\n\nError the first\nError the second\nError the third\n"
    out_nh      = "Output the first\nOutput the second\nOutput the third\n"
    err_nh      = "Error the first\nError the second\nError the third\n"

    cmd = "#{@sshr} --long localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal outerr, io.gets(nil) }

    cmd = "#{@sshr} -l -b localhost '#{@dir}/helper_test_cmd.rb one two three'"
    IO.popen(cmd) { |io| assert_equal outerr, io.gets(nil) }

    cmd = "#{@sshr} --long -o localhost -- #{@dir}/helper_test_cmd.rb one two three"
    IO.popen(cmd) { |io| assert_equal out, io.gets(nil) }

    cmd = "#{@sshr} -l -e localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal err, io.gets(nil) }

    cmd = "#{@sshr} --long -x localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal out, io.gets(nil) }


    # --no-hostname versions
    cmd = "#{@sshr} --nh --long localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal outerr_nh, io.gets(nil) }

    cmd = "#{@sshr} -l -b --no-hostname localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal outerr_nh, io.gets(nil) }

    cmd = "#{@sshr} --long -o --nh localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal out_nh, io.gets(nil) }

    cmd = "#{@sshr} -l --no-hostname -e localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal err_nh, io.gets(nil) }

    cmd = "#{@sshr} --long --no-hostname -x localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal out_nh, io.gets(nil) }
  end

  def test_short
    outerr      = "Output the first\nError the first\n"
    out         = "Output the first\n"
    err         = "Error the first\n"
    user        = "#{ENV['USER']}\n"
    root        = "root\n"
    outerr_h    = "localhost:           Output the first\nlocalhost:           Error the first\n"
    out_h       = "localhost:           #{out}"
    err_h       = "localhost:           #{err}"
    user_h      = "localhost:           #{user}"
    root_h      = "localhost:           #{root}"

    # default (--no-hostname) versions
    cmd = "#{@sshr} --short localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal out, io.gets(nil) }

    cmd = "#{@sshr} --no-hostname -s -b localhost '#{@dir}/helper_test_cmd.rb one two three'"
    IO.popen(cmd) { |io| assert_equal outerr, io.gets(nil) }

    cmd = "#{@sshr} --short -o localhost -- #{@dir}/helper_test_cmd.rb one two three"
    IO.popen(cmd) { |io| assert_equal out, io.gets(nil) }

    cmd = "#{@sshr} -s -e localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal err, io.gets(nil) }

    cmd = "#{@sshr} --no-hostname --short -x localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal out, io.gets(nil) }

    # TODO: figure out how to mock this instead of requiring root ssh and whoami
    cmd = "#{@sshr} localhost whoami"
    IO.popen(cmd) { |io| assert_equal user, io.gets(nil) }

    cmd = "#{@sshr} --user root localhost whoami"
    IO.popen(cmd) { |io| assert_equal root, io.gets(nil) }


    # --show-hostname versions
    cmd = "#{@sshr} --short -H localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal out_h, io.gets(nil) }

    cmd = "#{@sshr} -s --show-hostname -b localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal outerr_h, io.gets(nil) }

    cmd = "#{@sshr} --short --show-hostname -o localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal out_h, io.gets(nil) }

    cmd = "#{@sshr} -sH -e localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal err_h, io.gets(nil) }

    cmd = "#{@sshr} --short -xH localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal out_h, io.gets(nil) }

    # TODO: figure out how to mock this instead of requiring root ssh and whoami
    cmd = "#{@sshr} --show-hostname localhost whoami"
    IO.popen(cmd) { |io| assert_equal user_h, io.gets(nil) }

    cmd = "#{@sshr} --show-hostname --user root localhost whoami"
    IO.popen(cmd) { |io| assert_equal root_h, io.gets(nil) }
  end

  def test_json
    json = "{\"stdout\":\"Output the first\\nOutput the second\\nOutput the third\",\"user\":\"\",\"json_class\":\"Net::SSHR::Result\",\"stderr\":\"Error the first\\nError the second\\nError the third\",\"exit_code\":0,\"cmd\":\"/export/home/gavin/work/sshr/test/helper_test_cmd.rb\",\"host\":\"localhost\",\"host_string\":\"localhost\"}\n"

    cmd = "#{@sshr} --json localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal json, io.gets(nil) }

    cmd = "#{@sshr} -j localhost #{@dir}/helper_test_cmd.rb"
    IO.popen(cmd) { |io| assert_equal json, io.gets(nil) }
  end
end

