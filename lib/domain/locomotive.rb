class Locomotive

	attr_reader :address, :protocol, :speed_steps, :speed, :direction, :lights

	def initialize(railway, address)
		@railway = railway
		@address = address
		@interface = @railway.register_locomotive(self)

		configuration = @interface.locomotive_configuration(@address)
		@protocol = configuration[:protocol]
		@speed_steps = configuration[:speed_steps]

		@speed = 0
		@direction = :forward
		@lights = false

		initial_status = @interface.locomotive_status(@address)
		@speed = initial_status[:speed]
		@direction = initial_status[:direction]
		@lights = initial_status[:lights]
	end

	def options=(options)
		@speed = options[:speed] if (options.has_key?(:speed))
		@direction = options[:direction] == :reverse ? :reverse : :forward if (options.has_key?(:direction))
		@lights = options[:lights] == true ? true : false if (options.has_key?(:lights))
		self.commit
	end

	def speed=(speed)
		change = @speed != speed
		@speed = speed
		self.commit if (change)
	end

	def direction=(direction)
		change = @direction != direction
		@direction = direction == :reverse ? :reverse : :forward
		self.commit if (change)
	end

	def lights=(lights)
		change = @lights != lights
		@lights = lights == true ? true : false
		self.commit if (change)
	end

	def update_status(status)
		change = @speed != status[:speed] || @direction != status[:direction] || @lights != status[:lights]
		@speed = status[:speed]
		@direction = status[:direction]
		@lights = status[:lights]
		self.handle_change(true) if (change)
	end

	def to_s
		"Locomotive ##{@address}: protocol=#{@protocol}, speed steps=#{@speed_steps}, speed=#{@speed}, direction=#{@direction}, lights=#{@lights}"
	end

	protected

	def commit
		@interface.locomotive(@address, @speed, @direction, @lights)
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