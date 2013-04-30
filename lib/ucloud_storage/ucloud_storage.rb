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
				true
			when 401 then false
			else raise TotalyWrongException
			end
		end

		def upload(file_path, box_name, destination)
			raise NotAuthorized if storage_url.nil?

			file = File.new(file_path)
			content_type = `file --mime-type #{file_path}`.split(": ").last
			response = HTTParty.put(storage_url+ "/#{box_name}/#{destination}",
															headers: {
																"X-Auth-Token" => auth_token,
																"Content-Type" => content_type,
																"Content-Length" => file.size.to_s },
															body: file.read)

			yield response if block_given?

			case response.code
			when 201 then true
			else false
			end
		end
	end
end