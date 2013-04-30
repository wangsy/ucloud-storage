VCR.configure do |c|
	c.cassette_library_dir = File.join(File.dirname(__FILE__), "../fixtures/vcr_cassettes")
  c.allow_http_connections_when_no_cassette = true
	c.hook_into :webmock
end