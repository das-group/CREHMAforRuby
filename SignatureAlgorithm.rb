class SignatureAlgorithm
	attr_reader :name
	def initialize(name)
		@name = name
	end

	def sign(sv,kid)
	end

	def verify(sv,kid,tbv)
	end
end