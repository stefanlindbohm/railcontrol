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

		self.update_status(@interface.locomotive_status(@address))
	end

	def options=(options)
		@speed = options[:speed] if (options.has_key?(:speed))
		@direction = options[:direction] == :reverse ? :reverse : :forward if (options.has_key?(:direction))
		@lights = options[:lights] == true ? true : false if (options.has_key?(:lights))
		self.commit
	end

	def speed=(speed)
		@speed = speed
		self.commit
	end

	def direction=(direction)
		@direction = direction == :reverse ? :reverse : :forward
		self.commit
	end

	def lights=(lights)
		@lights = lights == true ? true : false
		self.commit
	end

	def update_status(status)
		@speed = status[:speed]
		@direction = status[:direction]
		@lights = status[:lights]
		puts self.to_s
	end

	def to_s
		"Locomotive ##{@address}: protocol=#{@protocol}, speed steps=#{@speed_steps}, speed=#{@speed}, direction=#{@direction}, lights=#{@lights}"
	end

	protected

	def commit
		@interface.locomotive(@address, @speed, @direction, @lights)
	end

end