# encoding: utf-8

module Keysms

require 'digest/md5'
require 'json'
require 'patron'

class KeyteqService
  attr_accessor :result

  def initialize(options = {})
    @options, @payload = {}, {}

    @options = @options.merge(options)
    @options[:url] ||= "https://app.keysms.no"
  end

  def authenticate(username, key)
    @options[:auth] = {}
    @options[:auth][:username] = username
    @options[:auth][:key] = key
    self
  end

  private

  def session
    return @session if defined?(@session)

    @session = Patron::Session.new
    @session.base_url = @options.fetch(:url)
    @session
  end

  def json_payload
    @json_payload ||= @payload.to_json
  end

  def signature
    Digest::MD5.hexdigest(json_payload + auth_key)
  end

  def auth_key
    @options[:auth][:key]
  end

  def username
    @options[:auth][:username]
  end

  def call
    data = {
      username: username,
      signature: signature,
      payload: json_payload
    }

    response = session.post(@options[:path], data)
    handle_response(response.body)
    @result
  end

  def handle_response(response_text)
    @result = JSON.parse(response_text)
    begin
      if (@result["ok"] == false)
        error_code = find_error_code(@result)
        if (error_code == "not_authed")
          raise NotAuthenticatedError.new(@result)
        elsif (error_code == "message_no_valid_receivers")
          raise NoValidReceiversError.new(@result)
        elsif (error_code == "message_internal_error")
          raise InternalError.new(@result)
        else
          raise SMSError.new(@result)
        end
      end
    rescue NoMethodError => e
      raise SMSError.new(@result)
    end
  end

  def find_error_code(structure)
    structure.each do | key, value |
      if (key == "code")
        return value
      elsif (key == "error")
        if (value.is_a? String)
          return value
        elsif (value.is_a? Hash)
          return find_error_code(value)
        end
      end
    end
  end

end

class SMS < KeyteqService
  def deliver(message, receivers, options = {})
    @options = @options.merge(options)
    @options[:path] = "/messages"

    @payload[:receivers] = [receivers].flatten
    @payload[:message] = message

    call
  end
end

class Info < KeyteqService
  def info
    @options[:path] = "/auth/current.json"

    @payload[:user] = true
    @payload[:account] = true

    call
  end
end

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
