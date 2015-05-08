module Fluent
  class SlackQuoteFilter < Filter
    Plugin.register_filter('slack_quote', self)

    def configure(conf)
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
        filtered_message = "> #{message}"
        record = record.dup.tap {|r| r['message'] = filtered_message }
      end
      record
    end
  end
end
