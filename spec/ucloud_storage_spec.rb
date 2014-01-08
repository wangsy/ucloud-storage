# encoding: utf-8
require_relative '../lib/ucloud_storage'
require 'httparty'
require 'vcr'
require 'support/vcr'
require 'yaml'

describe UcloudStorage do
  context "set user/pass info" do
    before do
      UcloudStorage.configure do |config|
        config.user = "abc@mintshop.com"
        config.pass = "my_api_key"
      end
    end

    it "can set default user/pass info" do
      UcloudStorage.user.should == "abc@mintshop.com"
      UcloudStorage.pass.should == "my_api_key"
    end

    it 'uses default uesr/pass info when initialized' do
      ucloud = UcloudStorage.new
      ucloud.user.should == "abc@mintshop.com"
      ucloud.pass.should == "my_api_key"
    end
  end

  let(:valid_ucloud) do
    file = File.open(File.join(File.dirname(__FILE__), "/support/auth_info.yml"))
    auth_info = YAML.load(file)
    ucloud = UcloudStorage.new(user: auth_info["valid_user"]["user"],
                               pass: auth_info["valid_user"]["pass"])
  end

  let(:valid_ucloud_lite) do
    file = File.open(File.join(File.dirname(__FILE__), "/support/auth_info.yml"))
    auth_info = YAML.load(file)
    ucloud = UcloudStorage.new(user: auth_info["valid_user"]["user"],
                               pass: auth_info["valid_user"]["pass"],
                               type: 'lite')
  end

  let(:invalid_ucloud) do
    invlaid_ucloud = UcloudStorage.new
    invlaid_ucloud.user = "invalid_user@mintshop.com"
    invlaid_ucloud.pass = "please download mintshop"
    invlaid_ucloud
  end

  let(:file_path) { File.join(File.dirname(__FILE__), "/fixtures/sample_file.txt") }
  let(:box) { 'dev_box' }
  let(:destination) { 'cropped_images/'+Pathname(file_path).basename.to_s }

  describe '#authorize' do
    it "can authorize with valid user/pass" do
      VCR.use_cassette("storage/v1/auth") do
        valid_ucloud.is_authorized?.should_not == true
        valid_ucloud.authorize.should == true
        valid_ucloud.storage_url.should_not be_nil
        valid_ucloud.auth_token.should_not be_nil
        valid_ucloud.is_authorized?.should == true
      end
    end

    it 'should be authorize with lite storage' do
      VCR.use_cassette("storage/v1/authlite") do
        valid_ucloud_lite.is_authorized?.should_not == true
        valid_ucloud_lite.authorize.should == true
        valid_ucloud_lite.storage_url.should_not be_nil
        valid_ucloud_lite.auth_token.should_not be_nil
        valid_ucloud_lite.is_authorized?.should == true
      end
    end

    it "cannot authorize with invalid user/pass" do
      VCR.use_cassette("storage/v1/auth_fail") do
        invalid_ucloud.authorize.should == false
        invalid_ucloud.storage_url.should be_nil
        invalid_ucloud.auth_token.should be_nil
      end
    end

    it 'yields response' do
      VCR.use_cassette("storage/v1/auth") do
        valid_ucloud.authorize do |response|
          response.code.should == 200
        end
      end
    end
  end

  describe "#upload" do
    it "can upload a file with proper url" do
      VCR.use_cassette("v1/put_storage_object") do
        valid_ucloud.authorize
        valid_ucloud.upload(file_path, box, destination).should be_true
        uploaded_url = "https://ssproxy.ucloudbiz.olleh.com/v1/AUTH_f46e842e-c688-460e-a70b-e6a4d30e9885/dev_box/cropped_images/sample_file.txt"
        HTTParty.get(uploaded_url).header.code_type.should == Net::HTTPOK
        valid_ucloud.delete(box, destination)
      end
    end

    it "should fail to upload with invalid file path" do
      VCR.use_cassette('storage/v1/auth') do
        valid_ucloud.authorize
        invalid_file_path = File.join(File.dirname(__FILE__), "/fixtures/no_sample_file.txt")
        expect {
          valid_ucloud.upload(invalid_file_path, box, destination)
        }.to raise_error(Errno::ENOENT)
      end
    end

    it "should fail to upload without authorization" do
      expect {
        valid_ucloud.upload(file_path, box, destination).should be_true
      }.to raise_error(UcloudStorage::NotAuthorized)
    end

    it "should retry to upload if authorization failure response" do
      VCR.use_cassette("v1/put_storage_object_with_auth_fail") do
        valid_ucloud.authorize
        valid_ucloud.auth_token += "a"

        valid_ucloud.upload(file_path, box, destination) do |response|
          response.code.should == 201
        end
        valid_ucloud.delete(box, destination)
      end
    end

    it 'yields response' do
      VCR.use_cassette("v1/put_storage_object") do
        valid_ucloud.authorize
        valid_ucloud.upload(file_path, box, destination) do |response|
          response.code.should == 201
        end
        valid_ucloud.delete(box, destination)
      end
    end
  end

  describe "#delete" do
    it 'should delete updated object' do
      VCR.use_cassette("v1/delete_storage_object_02") do
        valid_ucloud.authorize
        valid_ucloud.upload(file_path, box, destination)

        valid_ucloud.delete(box, destination) do |response|
          response.code.should == 204
        end.should == true
        uploaded_url = "https://ssproxy.ucloudbiz.olleh.com/v1/AUTH_f46e842e-c688-460e-a70b-e6a4d30e9885/dev_box/cropped_images/sample_file.txt"
        HTTParty.get(uploaded_url).header.code_type.should == Net::HTTPNotFound
      end
    end
  end

  describe "#exist" do
    it "should retry to upload if authorization failure response" do
      VCR.use_cassette("v1/object_exists") do
        valid_ucloud.authorize
        valid_ucloud.upload(file_path, box, destination) do |response|
          response.code.should == 201
        end

        valid_ucloud.auth_token += "a"

        valid_ucloud.get(box, destination) do |response|
          [200, 304].should include(response.code)
        end.should == true
      end
    end

    it 'should get updated object' do
      VCR.use_cassette("v1/get_updated_object") do
        valid_ucloud.authorize
        valid_ucloud.upload(file_path, box, destination)

        result = false
        valid_ucloud.get(box, destination) do |response|
          result = true
          [200, 304].should include(response.code)
        end
        result.should == true
        valid_ucloud.delete(box, destination)
      end
    end
  end
end
