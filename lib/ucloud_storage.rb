require_relative 'ucloud_storage/ucloud_storage'
require_relative 'ucloud_storage/configuration'
require_relative 'ucloud_storage/version'
require 'forwardable'

module UcloudStorage
  class << self
    extend Forwardable
    def_delegators Configuration, :user, :pass, :configure
  end

	def self.new(options={})
		UcloudStorage.new(options)
	end
end