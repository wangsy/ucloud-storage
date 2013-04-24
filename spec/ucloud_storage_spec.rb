# encoding: utf-8
require_relative '../lib/ucloud_storage'
require 'httparty'
require 'vcr'
require 'support/vcr'
require 'yaml'

describe UcloudStorage do
	let(:valid_ucloud) do
		ucloud = UcloudStorage.new
		file = File.open(File.join(File.dirname(__FILE__), "/support/auth_info.yml"))
		auth_info = YAML.load(file)
		ucloud.user = auth_info["valid_user"]["user"]
		ucloud.pass = auth_info["valid_user"]["pass"]
		ucloud		
	end

	let(:invalid_ucloud) do
		invlaid_ucloud = UcloudStorage.new
		invlaid_ucloud.user = "invalid_user@mintshop.com"
		invlaid_ucloud.pass = "please download mintshop"
		invlaid_ucloud
	end

	it "can authorize with valid user/pass" do
		VCR.use_cassette("storage/v1/auth") do 
			valid_ucloud.authorize.should == true
			valid_ucloud.storage_url.should_not be_nil
			valid_ucloud.auth_token.should_not be_nil
		end
	end

	it "cannot authorize with invalid user/pass" do
		VCR.use_cassette("storage/v1/auth_fail") do 
			invalid_ucloud.authorize.should == false
			invalid_ucloud.storage_url.should be_nil
			invalid_ucloud.auth_token.should be_nil
		end
	end

	it "can upload a file" do
		VCR.use_cassette('storage/v1/auth') do
			valid_ucloud.authorize
		end

		file_path = File.join(File.dirname(__FILE__), "/fixtures/sample_file.txt")
		box = 'dev'
		destination = 'cropped_images/'+Pathname(file_path).basename.to_s

		VCR.use_cassette("v1/put_storage_object") do
			valid_ucloud.upload(file_path, box, destination).should be_true
		end
	end

	it "should fail to upload with invalid file path" do
		VCR.use_cassette('storage/v1/auth') do
			valid_ucloud.authorize
		end

		file_path = File.join(File.dirname(__FILE__), "/fixtures/no_sample_file.txt")
		box = 'dev'
		destination = 'cropped_images/'+Pathname(file_path).basename.to_s

		expect {
			valid_ucloud.upload(file_path, box, destination)
		}.to raise_error(Errno::ENOENT)
	end

	it "should fail to upload without authorization" do
		file_path = File.join(File.dirname(__FILE__), "/fixtures/sample_file.txt")
		box = 'dev'
		destination = 'cropped_images/'+Pathname(file_path).basename.to_s

		expect {
			valid_ucloud.upload(file_path, box, destination).should be_true
		}.to raise_error(UcloudStorage::NotAuthorized)
	end
end