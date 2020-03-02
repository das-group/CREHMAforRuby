require "openssl"
require "base64"
require './SignatureAlgorithm'

class SimpleHMACSHA256 < SignatureAlgorithm
	def initialize
		super("HMAC/SHA256")
		@verified_signatures = Array.new
	end
	def sign(tbs,key)
		return Base64.urlsafe_encode64(OpenSSL::HMAC.digest('sha256', key, tbs)).gsub("=","")
	end

	def verify(sv,kid,tbv)
		@verified_signatures
	end
end