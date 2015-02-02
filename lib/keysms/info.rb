# encoding: utf-8

module Keysms
  class Info < KeyteqService
    def info
      @options[:path] = "/auth/current.json"

      @payload[:user] = true
      @payload[:account] = true

      call
    end
  end
end
