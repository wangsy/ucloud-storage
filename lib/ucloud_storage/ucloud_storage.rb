# encoding: utf-8
require 'httparty'

module UcloudStorage
  class TotalyWrongException < StandardError; end
  class NotAuthorized < StandardError; end

  class UcloudStorage
    attr_accessor :user, :pass, :storage_url, :auth_token

    def initialize(options={})
      @user = options.fetch(:user) { Configuration.user }
      @pass = options.fetch(:pass) { Configuration.pass }
      @authorized = false
    end

    def authorize
      response = HTTParty.get("https://api.ucloudbiz.olleh.com/storage/v1/auth/",
                              headers: { "X-Storage-User" => user,
                                         "X-Storage-Pass" => pass })

      yield response if block_given?

      case response.code
      when 200
        self.storage_url = response.headers["X-Storage-Url"]
        self.auth_token = response.headers["X-Auth-Token"]
        @authorized = true
      when 401 then false
      else raise TotalyWrongException
      end
    end

    def is_authorized?
      @authorized
    end

    def upload(file_path, box_name, destination, &block)
      raise NotAuthorized if storage_url.nil?

      file = File.new(file_path)
      content_type = `file --mime-type #{file_path}`.split(": ").last

      upload_blob(file.read, box_name, destination, content_type, &block)

    end

    def upload_blob(blob, box_name, destination, content_type, &block)
      raise NotAuthorized if storage_url.nil?

      response = HTTParty.put(storage_url+ "/#{box_name}/#{destination}",
                              headers: {
                                "X-Auth-Token" => auth_token,
                                "Content-Type" => content_type,
                                "Content-Length" => blob.size.to_s },
                              body: blob)

      if response.code == 401 and authorize
        return upload_blob(blob, box_name, destination, content_type, &block)
      end

      yield response if block_given?

      response.code == 201 ? true : false
    end

    def delete(box_name, destination)
      raise NotAuthorized if storage_url.nil?

      response = HTTParty.delete(storage_url+ "/#{box_name}/#{destination}",
                                 headers: { "X-Auth-Token" => auth_token })

      yield response if block_given?

      response.code == 204 ? true : false
    end

    def get(box_name, destination)
      raise NotAuthorized if storage_url.nil?

      response = HTTParty.get(storage_url+ "/#{box_name}/#{destination}",
                                 headers: { "X-Auth-Token" => auth_token })

      yield response if block_given?

      [200, 304].include?(response.code) ? true : false
    end

    def exist?(box_name, destination)
      raise NotAuthorized if storage_url.nil?

      response = HTTParty.head(storage_url+ "/#{box_name}/#{destination}",
                                 headers: { "X-Auth-Token" => auth_token })
      
      [200, 204].include?(response.code) ? true : false # Adding 200 for Ucloud's way
    end
  end
end