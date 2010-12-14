# Net::SSHR::Formatter tests

require 'test/unit'
require 'net/sshr/result'
require 'net/sshr/formatter'

class TestNetSSHRFormatter < Test::Unit::TestCase
  def setup 
    @dir = File.join(Dir.getwd, File.dirname($0))
    @sshr = File.join(@dir, '..', 'bin', 'sshr')
    @result = Net::SSHR::Result.new(
      'localhost',
      'random_cmd',
      "Output the first\nOutput the second\n",
      "Error the first\nError the second\n",
      0)
    @stderr_result = Net::SSHR::Result.new(
      'localhost',
      'random_cmd',
      '',
      "Error the first\nError the second\n",
      0)
  end

  def test_long
    outerr      = "[localhost]\nOutput the first\nOutput the second\n\nError the first\nError the second\n\n"
    out         = "[localhost]\nOutput the first\nOutput the second\n\n"
    err         = "[localhost]\nError the first\nError the second\n\n"
    outerr_nh   = "Output the first\nOutput the second\n\nError the first\nError the second\n\n"
    out_nh      = "Output the first\nOutput the second\n\n"
    err_nh      = "Error the first\nError the second\n\n"

    # Long defaults
    fmt = Net::SSHR::Formatter.new({
      :format           => :long,
    })
    assert_equal(outerr, fmt.render(@result))

    # Long both
    fmt = Net::SSHR::Formatter.new({
      :format           => :long,
      :out_err_selector => :oe_both,
    })
    assert_equal(outerr, fmt.render(@result))

    # Long stdout only
    fmt = Net::SSHR::Formatter.new({
      :format           => :long,
      :out_err_selector => :oe_out,
    })
    assert_equal(out, fmt.render(@result))

    # Long stderr only
    fmt = Net::SSHR::Formatter.new({
      :format           => :long,
      :out_err_selector => :oe_err,
    })
    assert_equal(err, fmt.render(@result))

    # Long xor
    fmt = Net::SSHR::Formatter.new({
      :format           => :long,
      :out_err_selector => :oe_xor,
    })
    assert_equal(out, fmt.render(@result))


    # Long no-hostname
    fmt = Net::SSHR::Formatter.new({
      :format           => :long,
      :show_hostname    => false,
    })
    assert_equal(outerr_nh, fmt.render(@result))

    # Long both no-hostname
    fmt = Net::SSHR::Formatter.new({
      :format           => :long,
      :out_err_selector => :oe_both,
      :show_hostname    => false,
    })
    assert_equal(outerr_nh, fmt.render(@result))

    # Long stdout only no-hostname
    fmt = Net::SSHR::Formatter.new({
      :format           => :long,
      :out_err_selector => :oe_out,
      :show_hostname    => false,
    })
    assert_equal(out_nh, fmt.render(@result))

    # Long stderr only no-hostname
    fmt = Net::SSHR::Formatter.new({
      :format           => :long,
      :out_err_selector => :oe_err,
      :show_hostname    => false,
    })
    assert_equal(err_nh, fmt.render(@result))

    # Long xor no-hostname
    fmt = Net::SSHR::Formatter.new({
      :format           => :long,
      :out_err_selector => :oe_xor,
      :show_hostname    => false,
    })
    assert_equal(out_nh, fmt.render(@result))
  end

  def test_short
    outerr      = "Output the first\nError the first\n"
    out         = "Output the first\n"
    err         = "Error the first\n"
    outerr_h    = "localhost:           Output the first\nlocalhost:           Error the first\n"
    out_h       = "localhost:           #{out}"
    err_h       = "localhost:           #{err}"

    # Short defaults
    fmt = Net::SSHR::Formatter.new({
      :format           => :short,
    })
    assert_equal(out, fmt.render(@result))

    # Short both
    fmt = Net::SSHR::Formatter.new({
      :format           => :short,
      :out_err_selector => :oe_both,
    })
    assert_equal(outerr, fmt.render(@result))

    # Short stdout only
    fmt = Net::SSHR::Formatter.new({
      :format           => :short,
      :out_err_selector => :oe_out,
    })
    assert_equal(out, fmt.render(@result))

    # Short stderr only
    fmt = Net::SSHR::Formatter.new({
      :format           => :short,
      :out_err_selector => :oe_err,
    })
    assert_equal(err, fmt.render(@result))

    # Short xor
    fmt = Net::SSHR::Formatter.new({
      :format           => :short,
      :out_err_selector => :oe_xor,
    })
    assert_equal(out, fmt.render(@result))

    # Short xor, no stdout
    fmt = Net::SSHR::Formatter.new({
      :format           => :short,
      :out_err_selector => :oe_xor,
    })
    assert_equal(err, fmt.render(@stderr_result))



    # Short defaults w/hostname
    fmt = Net::SSHR::Formatter.new({
      :format           => :short,
      :show_hostname    => :true,
    })
    assert_equal(out_h, fmt.render(@result))

    # Short both w/hostname
    fmt = Net::SSHR::Formatter.new({
      :format           => :short,
      :out_err_selector => :oe_both,
      :show_hostname    => :true,
    })
    assert_equal(outerr_h, fmt.render(@result))

    # Short stdout only w/hostname
    fmt = Net::SSHR::Formatter.new({
      :format           => :short,
      :out_err_selector => :oe_out,
      :show_hostname    => :true,
    })
    assert_equal(out_h, fmt.render(@result))

    # Short stderr only w/hostname
    fmt = Net::SSHR::Formatter.new({
      :format           => :short,
      :out_err_selector => :oe_err,
      :show_hostname    => :true,
    })
    assert_equal(err_h, fmt.render(@result))

    # Short xor w/hostname
    fmt = Net::SSHR::Formatter.new({
      :format           => :short,
      :out_err_selector => :oe_xor,
      :show_hostname    => :true,
    })
    assert_equal(out_h, fmt.render(@result))
    #
    # Short xor, no stdout, w/hostname
    fmt = Net::SSHR::Formatter.new({
      :format           => :short,
      :out_err_selector => :oe_xor,
      :show_hostname    => :true,
    })
    assert_equal(err_h, fmt.render(@stderr_result))
  end

  def test_json
    json = "{\"stdout\":\"Output the first\\nOutput the second\",\"user\":\"\",\"json_class\":\"Net::SSHR::Result\",\"stderr\":\"Error the first\\nError the second\",\"exit_code\":0,\"cmd\":\"random_cmd\",\"host\":\"localhost\",\"host_string\":\"localhost\"}\n"

    fmt = Net::SSHR::Formatter.new({
      :format       => :json,
    })
    assert_equal(json, fmt.render(@result))
  end

  def test_list
    fmt = Net::SSHR::Formatter.new({
      :format       => :list,
    })
    assert_equal("localhost\n", fmt.render(@result))
  end

  def test_quiet
    fmt = Net::SSHR::Formatter.new({
      :format       => :long,
      :quiet        => true,
    })
    assert_equal('', fmt.render(@stderr_result))

    fmt = Net::SSHR::Formatter.new({
      :format       => :short,
      :quiet        => true,
    })
    assert_equal('', fmt.render(@stderr_result))

    fmt = Net::SSHR::Formatter.new({
      :format       => :json,
      :quiet        => true,
    })
    assert_equal('', fmt.render(@stderr_result))
  end
end

