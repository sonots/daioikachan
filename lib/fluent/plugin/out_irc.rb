module Fluent
  class IRCOutput < Fluent::Output
    Fluent::Plugin.register_output('irc', self)

    include SetTimeKeyMixin
    include SetTagKeyMixin

    config_set_default :include_time_key, true
    config_set_default :include_tag_key, true

    config_param :host        , :string  , :default => 'localhost'
    config_param :port        , :integer , :default => 6667
    config_param :channel     , :string
    config_param :channel_keys, :default => nil do |val|
      val.split(',')
    end
    config_param :nick        , :string  , :default => 'fluentd'
    config_param :user        , :string  , :default => 'fluentd'
    config_param :real        , :string  , :default => 'fluentd'
    config_param :password    , :string  , :default => nil
    config_param :message     , :string
    config_param :out_keys do |val|
      val.split(',')
    end
    config_param :time_key    , :string  , :default => 'time'
    config_param :time_format , :string  , :default => '%Y/%m/%d %H:%M:%S'
    config_param :tag_key     , :string  , :default => 'tag'
    config_param :command     , :string  , :default => 'privmsg'
    config_param :command_keys, :default => nil do |val|
      val.split(',')
    end

    config_param :blocking_timeout, :time,    :default => 0.5
    config_param :max_send_queue,   :integer, :default => 100
    config_param :send_interval,    :time,    :default => 2

    COMMAND_MAP = {
      'priv_msg' => :priv_msg,
      'privmsg'  => :priv_msg,
      'notice'   => :notice,
    }

    # To support log_level option implemented by Fluentd v0.10.43
    unless method_defined?(:log)
      define_method("log") { $log }
    end

    attr_reader :conn # for test

    def initialize
      super
      require 'irc_parser'
    end

    def configure(conf)
      super

      begin
        @message % (['1'] * @out_keys.length)
      rescue ArgumentError
        raise Fluent::ConfigError, "string specifier '%s' and out_keys specification mismatch"
      end

      if @channel_keys
        begin
          @channel % (['1'] * @channel_keys.length)
        rescue ArgumentError
          raise Fluent::ConfigError, "string specifier '%s' and channel_keys specification mismatch"
        end
      end
      @channel = '#'+@channel

      if @command_keys
        begin
          @command % (['1'] * @command_keys.length)
        rescue ArgumentError
          raise Fluent::ConfigError, "string specifier '%s' and command_keys specification mismatch"
        end
      else
        unless @command = COMMAND_MAP[@command]
          raise Fluent::ConfigError, "command must be one of #{COMMAND_MAP.keys.join(', ')}"
        end
      end

      @send_queue = []
    end

    def start
      super

      begin
        @loop = Coolio::Loop.new
        @conn = create_connection
        @timer = TimerWatcher.new(@send_interval, true, log, &method(:on_timer))
        @loop.attach(@timer)
        @thread = Thread.new(&method(:run))
      rescue => e
        puts e
        raise Fluent::ConfigError, "failed to connect IRC server #{@host}:#{@port}"
      end
    end

    def shutdown
      super
      @loop.watchers.each { |w| w.detach }
      @loop.stop
      @conn.close
      @thread.join
    end

    def run
      @loop.run(@blocking_timeout)
    rescue => e
      log.error "unexpected error", :error => e, :error_class => e.class
      log.error_backtrace
    end

    def emit(tag, es, chain)
      chain.next

      if @conn.closed?
        log.warn "out_irc: connection is closed. try to reconnect"
        @conn = create_connection
      end

      es.each do |time,record|
        if @send_queue.size >= @max_send_queue
          log.warn "out_irc: send queue size exceeded max_send_queue(#{@max_send_queue}), discards"
          break
        end

        filter_record(tag, time, record)
        command, channel, message = build_command(record), build_channel(record), build_message(record)
        log.debug { "out_irc: push {command:\"#{command}\", channel:\"#{channel}\", message:\"#{message}\"}" }
        @send_queue.push([command, channel, message])
      end
    end

    def on_timer
      return if @send_queue.empty?
      command, channel, message = @send_queue.shift
      log.info { "out_irc: send {command:\"#{command}\", channel:\"#{channel}\", message:\"#{message}\"}" }
      @conn.send_message(command, channel, message)
    end

    private

    def create_connection
      conn = IRCConnection.connect(@host, @port)
      conn.log  = log
      conn.nick = @nick
      conn.user = @user
      conn.real = @real
      conn.password = @password
      conn.attach(@loop)
      conn
    end

    def build_message(record)
      values = fetch_keys(record, @out_keys)
      @message % values
    end

    def build_channel(record)
      return @channel unless @channel_keys

      values = fetch_keys(record, @channel_keys)
      @channel % values
    end

    def build_command(record)
      return @command unless @command_keys

      values = fetch_keys(record, @command_keys)
      unless command = COMMAND_MAP[@command % values]
        log.warn "out_irc: command is not one of #{COMMAND_MAP.keys.join(', ')}, use privmsg"
      end
      command || :priv_msg
    end

    def fetch_keys(record, keys)
      Array(keys).map do |key|
        begin
          record.fetch(key).to_s
        rescue KeyError
          log.warn "out_irc: the specified key '#{key}' not found in record. [#{record}]"
          ''
        end
      end
    end

    class TimerWatcher < Coolio::TimerWatcher
      def initialize(interval, repeat, log, &callback)
        @callback = callback
        @log = log
        super(interval, repeat)
      end

      def on_timer
        @callback.call
      rescue
        @log.error $!.to_s
        @log.error_backtrace
      end
    end

    class IRCConnection < Cool.io::TCPSocket
      attr_reader :joined # for test
      attr_accessor :log, :nick, :user, :real, :password

      def initialize(*args)
        super
        @joined = {}
      end

      def on_connect
        if @password
          IRCParser.message(:pass) do |m|
            m.password = @password
            write m
          end
        end
        IRCParser.message(:nick) do |m|
          m.nick   = @nick
          write m
        end
        IRCParser.message(:user) do |m|
          m.user = @user
          m.postfix = @real
          write m
        end
      end

      def on_read(data)
        err_nick_name_in_use = nil
        data.each_line do |line|
          begin
            msg = IRCParser.parse(line)
            log.debug { "out_irc: on_read :#{msg.class.to_sym}" }
            case msg.class.to_sym
            when :rpl_welcome
              log.info { "out_irc: welcome \"#{msg.nick}\" to \"#{msg.prefix}\"" }
            when :ping
              IRCParser.message(:pong) do |m|
                m.target = msg.target
                m.body = msg.body
                write m
              end
            when :join
              log.info { "out_irc: joined to #{msg.channels.join(', ')}" }
              msg.channels.each {|channel| @joined[channel] = true }
            when :err_nick_name_in_use
              log.warn "out_irc: nickname \"#{msg.error_nick}\" is already in use. use \"#{msg.error_nick}_\" instead."
              err_nick_name_in_use = true
              @nick = "#{msg.error_nick}_"
            when :error
              log.warn "out_irc: an error occured. \"#{msg.error_message}\""
            end
          rescue
            #TODO
          end
        end

        if err_nick_name_in_use
          self.on_connect
        end
      end

      def joined?(channel)
        @joined[channel]
      end

      def join(channel)
        IRCParser.message(:join) do |m|
          m.channels = channel
          write m
        end
        log.debug { "out_irc: join to #{channel}" }
      end

      def send_message(command, channel, message)
        join(channel) unless joined?(channel)
        IRCParser.message(command) do |m|
          m.target = channel
          m.body = message
          write m
        end
        channel # return channel for test
      end
    end
  end
end
