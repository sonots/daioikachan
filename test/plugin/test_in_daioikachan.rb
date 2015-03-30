require_relative '../helper'
require 'fluent/plugin/in_daioikachan'
require 'net/https'

class DaioikachanInputTest < Test::Unit::TestCase
  def post(path, params, header = {}, ssl = false)
    http = Net::HTTP.new("127.0.0.1", PORT)
    if ssl
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    req = Net::HTTP::Post.new(path, header)
    if params.is_a?(String)
      req.body = params
    else
      req.set_form_data(params)
    end
    http.request(req)
  end

  def post_multipart(path, params, header = {}, ssl = false)
    http = Net::HTTP.new("127.0.0.1", PORT)
    if ssl
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    req = Net::HTTP::Post.new(path, header)
    req.set_content_type("multipart/form-data; boundary=myboundary")

    body = ""
    params.each do |key, val|
      body.concat("--myboundary\r\n")
      body.concat("content-disposition: form-data; name=\"#{key}\";\r\n")
      body.concat("\r\n")
      body.concat("#{val}\r\n")
    end
    body.concat("--myboundary--\r\n")
    req.body = body

    http.request(req)
  end

  def setup
    Fluent::Test.setup
  end

  PORT = unused_port
  CONFIG = %[
    port #{PORT}
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::InputTestDriver.new(Fluent::DaioikachanInput).configure(conf, true)
  end

  def test_default_configure
    d = create_driver(%[])
    assert_equal 4979,      d.instance.port
    assert_equal '0.0.0.0', d.instance.bind
    assert_equal 0,         d.instance.min_threads
    assert_equal 4,         d.instance.max_threads
    assert_equal nil,       d.instance.backlog
  end

  def test_configure
    d = create_driver(%[
      port #{PORT}
      bind 127.0.0.1
      min_threads 0
      max_threads 4
      backlog 1024
    ])
    assert_equal PORT,        d.instance.port
    assert_equal '127.0.0.1', d.instance.bind
    assert_equal 0,           d.instance.min_threads
    assert_equal 4,           d.instance.max_threads
    assert_equal 1024,        d.instance.backlog
  end

  def test_notice
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    Fluent::Engine.now = time

    d.expect_emit "notice.channel", time, {"command" => "notice", "channel" => "channel", "message" => "message"}

    d.run do
      d.expected_emits.each {|tag, time, record|
        res = post("/notice", {command: "notice", channel: "channel", message: "message"})
        assert_equal "200", res.code
      }
    end
  end

  def test_privmsg
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    Fluent::Engine.now = time

    d.expect_emit "privmsg.channel", time, {"command" => "privmsg", "channel" => "channel", "message" => "message"}

    d.run do
      d.expected_emits.each {|tag, time, record|
        res = post("/privmsg", {command: "privmsg", channel: "channel", message: "message"})
        assert_equal "200", res.code
      }
    end
  end

  def test_join
    d = create_driver
    d.run do
      res = post("/join", {})
      assert_equal "200", res.code
    end
  end

  def test_leave
    d = create_driver
    d.run do
      res = post("/leave", {})
      assert_equal "200", res.code
    end
  end


  def test_multipart
    d = create_driver

    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    Fluent::Engine.now = time

    d.expect_emit "privmsg.channel", time, {"command" => "privmsg", "channel" => "channel", "message" => "message"}

    d.run do
      d.expected_emits.each {|tag, time, record|
        res = post_multipart("/privmsg", {command: "privmsg", channel: "channel", message: "message"})
        assert_equal "200", res.code
      }
    end
  end
end
