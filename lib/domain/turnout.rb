class Turnout

	attr_reader :address, :color

	def initialize(railway, address)
		@railway = railway
		@address = address
		@color = :green
		@interface = @railway.register_turnout(self)

		self.update_status(@interface.turnout_status(@address))
	end

	def toggle
		self.color = @color == :green ? :red : :green
	end

	def color=(color)
		@color = color == :green ? :green : :red
		self.commit
	end

	def update_status(status)
		@color = status[:color]
		puts self.to_s
	end

	def to_s
		"Turnout #{@address}: color=#{@color}"
	end

	protected

	def commit
		@interface.turnout(@address, @color, true)
		@interface.turnout(@address, @color, false)
	end
end