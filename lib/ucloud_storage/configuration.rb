# encoding: utf-8

module UcloudStorage
  module Configuration
    class << self
      attr_accessor :user
      attr_accessor :pass
    end

    def self.configure
      yield self
    end
  end
end