require 'string/scrub' if RUBY_VERSION.to_f < 2.1

module Fluent
  class StringIrcSlackFilter < Filter
    Plugin.register_filter('string_irc_slack', self)

    COLOR_CODE = "\x03" # \u0003
    BOLD       = "\x02" # \u0002
    UNDERLINE  = "\x1f" # \u001F
    INVERSE    = "\x16" # \u0016
    CLEAR      = "\x0f" # \u000F

    def configure(conf)
      @start_code = Regexp.new("(#{COLOR_CODE}[0-9][0-9](,[0-9][0-9])?|#{BOLD}|#{UNDERLINE}|#{INVERSE})+")
      @stop_code  = Regexp.new(CLEAR)
      super
    end

    def start
      super
    end

    def shutdown
      super
    end

    def filter(tag, time, record)
      if message = record['message']
        filtered_message = with_scrub(message) {|str| str.gsub(@start_code, '`').gsub(@stop_code, '`') }
        record = record.dup.tap {|r| r['message'] = filtered_message }
      end
      record
    end

    def with_scrub(string)
      begin
        return yield(string)
      rescue ArgumentError => e
        raise e unless e.message.index("invalid byte sequence in") == 0
        log.info "filter_string_irc_slack: invalid byte sequence is replaced in #{string}"
        string.scrub!('?')
        retry
      end
    end
  end
end
