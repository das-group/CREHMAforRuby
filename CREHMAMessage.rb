class CREHMAMessage
	attr_accessor :version, :body, :headers
	def initialize
    	@version = "1.1"
    	@headers = Hash.new
		@body = nil
  	end
end