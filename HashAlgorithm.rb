class HashAlgorithm
	attr_reader :hash_of_empty_body, :name
	def initialize(name,hash_of_empty_body)
		@name = name
		@hash_of_empty_body = hash_of_empty_body
	end

	def generate_hash(body)
	end

end