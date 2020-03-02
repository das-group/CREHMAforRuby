require './CREHMAMessage'
class CREHMAResponse < CREHMAMessage
	attr_accessor :status_code
	def initialize(status_code)
    	super()
    	@status_code = status_code
  	end
end