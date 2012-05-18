class Turnout

	attr_reader :address, :color

	def initialize(railway, address)
		@railway = railway
		@address = address
		@color = :green
		@interface = @railway.register_turnout(self)

		initial_status = @interface.turnout_status(@address)
		@color = initial_status[:color]
	end

	def toggle
		self.color = @color == :green ? :red : :green
	end

	def color=(color)
		change = @color != color
		@color = color == :green ? :green : :red
		self.commit if (change)
	end

	def update_status(status)
		change = @color != status[:color]
		@color = status[:color]
		self.handle_change(true) if (change)
	end

	def to_s
		"Turnout #{@address}: color=#{@color}"
	end

	protected

	def commit
		@interface.turnout(@address, @color)
		self.handle_change(false)
	end

	def handle_change(external)
		if (external)
			puts "External change: #{self.to_s}"
		else
			puts "Internal change: #{self.to_s}"
		end
	end

end