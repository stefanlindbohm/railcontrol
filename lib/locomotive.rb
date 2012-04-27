class Locomotive

	attr_reader :address, :speed, :direction, :lights

	def initialize(railway, address)
		@railway = railway
		@address = address
		@interface = @railway.register_locomotive(self)

		@speed = 0
		@direction = :forward
		@lights = false
	end

	def options=(options)
		@speed = options[:speed] if (options.has_key?(:speed))
		@direction = options[:direction] == :reverse ? :reverse : :forward if (options.has_key?(:direction))
		@lights = options[:lights] == true ? true : false if (options.has_key?(:lights))
		self.update
	end

	def speed=(speed)
		@speed = speed
		self.update
	end

	def direction=(direction)
		@direction = direction == :reverse ? :reverse : :forward
		self.update
	end

	def lights=(lights)
		@lights = lights == true ? true : false
		self.update
	end

	protected

	def update
		@interface.locomotive(@address, @speed, @direction, @lights)
	end

end