# encoding: utf-8

module Keysms
  class KeyteqService
    attr_accessor :result

    def initialize(options = {})
      @options, @payload = {}, {}

      @options = @options.merge(options)
      @options[:url]             ||= "https://app.keysms.no"
      @options[:connect_timeout] ||= 5
      @options[:timeout]         ||= 10
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

      @session                 = Patron::Session.new
      @session.connect_timeout = @options.fetch(:connect_timeout).to_i
      @session.timeout         = @options.fetch(:timeout).to_i
      @session.base_url        = @options.fetch(:url)
      @session.headers['User-Agent'] = "KeysmsRuby/#{Keysms::VERSION}"
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
end
