require 'spec_helper'

describe User do

	before do
    @user = User.new do |u|
      u.first_name = "Example User"
      u.last_name = "Example User"
      u.email = "user@example.com"
      u.token = "example_token"
      u.device_token = "example_device_token"
    end
  end

	subject { @user }

  it { should respond_to(:token) }
	it { should respond_to(:device_token) }
	it { should respond_to(:first_name) }
	it { should respond_to(:last_name) }
	it { should respond_to(:email) }
	it { should respond_to(:admin) }
	it { should respond_to(:count_sweetch) }
	it { should respond_to(:facebook_id) }
	it { should respond_to(:customer_token) }

	it { should be_valid }
  it { should_not be_admin }

  describe "with admin attribute set to 'true'" do
    before do
      @user.save!
      @user.toggle!(:admin)
    end

    it { should be_admin }
  end

	describe "when token is not present" do
    before { @user.token = " " }
    it { should_not be_valid }
	end

	describe "when first name is not present" do
  	before { @user.first_name = " " }
  	it { should_not be_valid }
	end

	describe "when last name is not present" do
  	before { @user.last_name = " " }
  	it { should_not be_valid }
	end

	describe "when email is not present" do
  	before { @user.email = " " }
  	it { should_not be_valid }
	end

	describe "when first name is too long" do
    before { @user.first_name = "a" * 51 }
    it { should_not be_valid }
	end

  describe "when last name is too long" do
    before { @user.last_name = "a" * 51 }
    it { should_not be_valid }
	end

	describe "when email format is invalid" do
    it "should be invalid" do
      addresses = %w[user@foo,com user_at_foo.org example.user@foo.
                     foo@bar_baz.com foo@bar+baz.com]
      addresses.each do |invalid_address|
        @user.email = invalid_address
        expect(@user).not_to be_valid
      end
    end
	end

  describe "when email format is valid" do
    it "should be valid" do
      addresses = %w[user@foo.COM A_US-ER@f.b.org frst.lst@foo.jp a+b@baz.cn]
      addresses.each do |valid_address|
        @user.email = valid_address
        expect(@user).to be_valid
      end
    end
	end

	describe "when email address is already taken" do
    before do
      user_with_same_email = @user.dup
      user_with_same_email.email = @user.email.upcase
      user_with_same_email.save
    end

    it { should_not be_valid }
	end

	describe "sweetch credits" do

	  it "should be created with 0" do
			expect(@user.credits).to eq(0)
		end

		it "should never be negative" do
			@user.credits = -3
			expect(@user).not_to be_valid
		end
	end

  describe "check if user is in a neighborhood operated by Sweetch", integration: true do
    before do
      # TODO -- override array ZIPCODE to ensure test can pass
      # stub_const(Distance::ZIPCODES, ["75015"])
      @wrong_location = Distance.new(lat: 48.5, lng: 2.4)
      @right_location = Distance.new(lat: 48.8476, lng: 2.2987)
    end

    it "sets userlocation to not available when out" do
      @user.location = @wrong_location
      expect(@user.as_resource(locate:true)[:location_available]).to eq(false)
    end

    it "sets userlocation available when in" do
      @user.location = @right_location
      expect(@user.as_resource(locate: true)[:location_available]).to eq(true)
    end

    it "does nothing if location not specified" do
      expect(@user.as_resource[:location_available]).to be_nil
    end
	end
end
