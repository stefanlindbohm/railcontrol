class Turnout

	attr_reader :color

	def initialize(railway, address)
		@railway = railway
		@address = address
		@color = :green
		@interface = @railway.register_turnout(self)
	end

	def color=(color)
		@color = color == :green ? :green : :red
		@interface.turnout(@address, @color, true)
		@interface.turnout(@address, @color, false)
	end

end