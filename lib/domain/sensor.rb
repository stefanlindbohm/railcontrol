class Sensor

	attr_reader :address, :active

	def initialize(railway, address)
		@railway = railway
		@address = address
		@interface = @railway.register_sensor(self)

		@active = false

		initial_status = @interface.sensor_status(address)
		@active = initial_status[:active]
	end

	def update_status(status)
		change = @active != status[:active]
		@active = status[:active]
		self.handle_change if (change)
	end

	def to_s
		"Sensor ##{@address}: active=#{@active}"
	end

	protected

	def handle_change
		puts "External change: #{self.to_s}"
	end

end