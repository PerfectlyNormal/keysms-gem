# encoding: utf-8

module Keysms
  class SMS < KeyteqService
    def deliver(message, receivers, options = {})
      @options[:path] = "/messages"

      @payload[:receivers] = [receivers].flatten
      @payload[:message] = message
      [:sender, :time, :date].each do |attr|
        if val = options.fetch(attr, nil)
          @payload[attr] = options.fetch(attr)
        end
      end

      call
    end
  end
end
