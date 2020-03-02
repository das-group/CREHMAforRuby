require "openssl"
require "./HashAlgorithm"

class SHA256 < HashAlgorithm
	def initialize()
		super("SHA256","47DEQpj8HBSa-_TImW-5JCeuQeRkm5NMpJWZG3hSuFU")
		@sha256 = OpenSSL::Digest::SHA256.new
	end

	def generate_hash(body)
		return @sha256.digest(body)
	end
end