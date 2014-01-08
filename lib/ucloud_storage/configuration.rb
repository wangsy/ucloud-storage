# encoding: utf-8

module UcloudStorage
  module Configuration
    class << self
      attr_accessor :user
      attr_accessor :pass
      attr_accessor :type
    end

    def self.configure
      yield self
    end
  end
end