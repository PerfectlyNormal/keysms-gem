# encoding: utf-8

require 'digest/md5'
require 'json'
require 'patron'

require 'keysms/keyteq_service'
require 'keysms/sms'
require 'keysms/info'

module Keysms
  class SMSError < StandardError
    attr_accessor :error
    def initialize(error)
      @error = error["error"]
      super
    end
  end

  class NotAuthenticatedError < SMSError
    attr_accessor :messages

    def initialize(error)
      @messages = error["messages"]
      super(error)
    end

    def to_s
      @messages.join(", ")
    end
  end

  class NoValidReceiversError < SMSError
    attr_accessor :failed_receivers

    def initialize(error)
      @failed_receivers = error["error"]["receivers"]["data"]["failed"]
      super(error)
    end

    def to_s
      @failed_receivers.join(", ")
    end
  end

  class InternalError < SMSError; end
end
