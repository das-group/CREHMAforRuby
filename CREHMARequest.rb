require './CREHMAMessage'
class CREHMARequest < CREHMAMessage
	attr_accessor :method, :target
	def initialize(method,target)
    	super()
    	@method = method
    	@target = target
  	end
end