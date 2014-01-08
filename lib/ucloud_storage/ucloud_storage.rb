# encoding: utf-8
require 'httparty'

module UcloudStorage
  class TotalyWrongException < StandardError; end
  class NotAuthorized < StandardError; end

  class UcloudStorage
    attr_accessor :user, :pass, :type, :storage_url, :auth_token

    def initialize(options={})
      @user = options.fetch(:user) { Configuration.user }
      @pass = options.fetch(:pass) { Configuration.pass }
      @type = options.fetch(:type) { Configuration.type || 'standard' }
      @authorized = false
    end

    def authorize
      response = HTTParty.get(auth_url, headers: { "X-Storage-User" => user,
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
      content_type = get_content_type(file_path)
      upload_blob(file.read, box_name, destination, content_type, &block)
    end

    def upload_blob(blob, box_name, destination, content_type, &block)
      raise NotAuthorized if storage_url.nil?

      target_url = File.join(storage_url, box_name, destination).to_s
      response = HTTParty.put(target_url,
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

    def delete(box_name, destination, &block)
      request(:delete, box_name, destination, [204], &block)
    end

    def get(box_name, destination, &block)
      request(:get, box_name, destination, [200, 304], &block)
    end

    def exist?(box_name, destination, &block)
      request(:head, box_name, destination, [200, 204], &block)
    end

    private

    def auth_url
      case type
      when "standard"
        "https://api.ucloudbiz.olleh.com/storage/v1/auth"
      when 'standard-jpn'
        "https://api.ucloudbiz.olleh.com/storage/v1/authjp"
      when "lite"
        "https://api.ucloudbiz.olleh.com/storage/v1/authlite"
      end
    end

    def request(method, box_name, destination, success_code = [200], &block)
      raise NotAuthorized if storage_url.nil?

      target_url = File.join(storage_url, box_name, destination)
      response = HTTParty.send(method, target_url, headers: { "X-Auth-Token" => auth_token })
      return request(method, box_name, destination, success_code) if response.code == 401 and authorize

      yield response if block_given?
      success_code.include?(response.code) ? true : false
    end

    #  stolen from http://stackoverflow.com/a/16636012/1802026
    def get_content_type(local_file_path)
      png = Regexp.new("\x89PNG".force_encoding("binary"))
      jpg = Regexp.new("\xff\xd8\xff\xe0\x00\x10JFIF".force_encoding("binary"))
      jpg2 = Regexp.new("\xff\xd8\xff\xe1(.*){2}Exif".force_encoding("binary"))
      case IO.read(local_file_path, 10)
      when /^GIF8/
        'image/gif'
      when /^#{png}/
        'image/png'
      when /^#{jpg}/
        'image/jpeg'
      when /^#{jpg2}/
        'image/jpeg'
      else
        if local_file_path.end_with? '.txt'
          'text/plain'
        else
          'application/octet-stream'
        end
        # mime_type = `file #{local_file_path} --mime-type`.gsub("\n", '') # Works on linux and mac
        # raise UnprocessableEntity, "unknown file type" if !mime_type
        # mime_type.split(':')[1].split('/')[1].gsub('x-', '').gsub(/jpeg/, 'jpg').gsub(/text/, 'txt').gsub(/x-/, '')
      end
    end

  end
end
