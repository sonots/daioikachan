module Fluent
  class DaioikachanInput < Input
    Plugin.register_input('daioikachan', self)

    def initialize
      require 'puma'
      require 'uri'
      super
    end

    config_param :port, :integer, :default => 4979
    config_param :bind, :string, :default => '0.0.0.0'
    config_param :min_threads, :integer, :default => 0
    config_param :max_threads, :integer, :default => 4
    config_param :backlog, :integer, :default => nil

    def configure(conf)
      super
    end

    def start
      super

      # Refer puma's Runner and Rack handler for puma server setup
      @server = ::Puma::Server.new(method(:on_request))
      @server.min_threads = @min_threads
      @server.max_threads = @max_threads
      @server.leak_stack_on_error = false
      setup_http

      @app = App.new(self)

      @thread = Thread.new(&method(:run))
    end

    def shutdown
      @server.stop(true)
      @thread.join
    end

    def run
      @server.run(false)
    rescue => e
      log.error "unexpected error", :error => e.to_s
      log.error_backtrace e.backtrace
    end

    def on_request(env)
      log.debug { "in_daioikachan: #{env.to_s}" }
      @app.run(env)
    end

    def setup_http
      log.info "listening http on #{@bind}:#{@port}"

      opts = [@bind, @port, true]
      opts << @backlog if @backlog
      @server.add_tcp_listener(*opts)
    end

    class App
      class BadRequest < StandardError; end
      class InternalServerError < StandardError; end
      class NotFound < StandardError; end

      attr_reader :router, :log

      def initialize(plugin)
        @router = plugin.router
        @log    = plugin.log
      end

      def run(env)
        # req = Rack::Request.new(env)
        method = env['REQUEST_METHOD'.freeze] # req.method
        path   = URI.parse(env['REQUEST_URI'.freeze]).path # req.path
        # Rack::Request.new should take care of this, but it did not
        if env['CONTENT_TYPE'.freeze].start_with?('multipart/form-data'.freeze)
          params = Rack::Multipart.parse_multipart(env)
        else
          body   = env['rack.input'].read # req.body.read
          params = Rack::Utils.parse_query(body)
        end

        begin
          if method == 'POST'
            case path
            when '/notice'
              notice(params)
            when '/privmsg'
              privmsg(params)
            when '/join'
              return ok
            when '/leave'
              return ok
            else
              return not_found
            end
          else
            return not_found
          end
        rescue BadRequest => e
          bad_request(e.message)
        rescue NotFound => e
          not_found(e.message)
        rescue InternalServerError => e
          internal_server_error(e.message)
        rescue => e
          internal_server_error("#{e.class} #{e.message} #{e.backtrace.first}")
        else
          ok
        end
      end

      def notice(params)
        channel, message = build_channel(params), build_message(params)
        tag    = "notice.#{channel}"
        record = params.merge('command' => 'notice', 'channel' => channel, 'message' => message)
        router.emit(tag, Fluent::Engine.now, record)
      end

      def privmsg(params)
        channel, message = build_channel(params), build_message(params)
        tag    = "privmsg.#{channel}"
        record = params.merge('command' => 'privmsg', 'channel' => channel, 'message' => message)
        router.emit(tag, Fluent::Engine.now, record)
      end

      private

      def build_channel(params)
        unless channel = params.delete('channel')
          raise BadRequest.new('`channel` parameter is mandatory')
        end
        if channel.start_with?('#')
          channel[1..-1] # remove starting #
        else
          channel
        end
      end

      def build_message(params)
        unless message = params.delete('message')
          raise BadRequest.new('`message` parameter is mandatory')
        end
        message # should I truncate message to max_length?
      end

      def ok(msg = nil)
        [200, {'Content-type'=>'text/plain'}, ["OK\n#{msg}"]]
      end

      def bad_request(msg = nil)
        [400, {'Content-type'=>'text/plain'}, ["Bad Request\n#{msg}"]]
      end

      def not_found(msg = nil)
        [404, {'Content-type'=>'text/plain'}, ["Not Found\n#{msg}"]]
      end

      def internal_server_error(msg = nil)
        [500, {'Content-type'=>'text/plain'}, ["Internal Server Error\n#{msg}"]]
      end
    end
  end
end
