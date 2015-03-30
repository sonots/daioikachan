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
        filtered_message = message.gsub(@start_code, '`').gsub(@stop_code, '`')
        record = record.dup.tap {|r| r['message'] = filtered_message }
      end
      record
    end
  end
end
