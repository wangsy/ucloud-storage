# UcloudStorage

Simple API for ucloud storage

## Installation

Add this line to your application's Gemfile:

    gem 'ucloud_storage'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ucloud_storage

## Usage

    ucloud = UcloudStorage.new(user: 'email', pass: 'API_KEY')

    ucloud.authoize
    # Upload
    ucloud.upload(filepath, boxname, destination)
    # Delete
    ucloud.delete(boxname, destination)
    # Get
    ucloud.get(boxname, destination)

## Configuration

Set default user/pass info

    UcloudStorage.configure do |config|
      config.user = 'email'
      config.pass = 'API KEY'
    end

## Response block

Every request yields a response

    ucloud.upload(filepath, boxname, dest) do |response|
      response_code = response.code
    end


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
