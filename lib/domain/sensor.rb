class Sensor

	attr_reader :address, :active

	def initialize(railway, address)
		@railway = railway
		@address = address
		@interface = @railway.register_sensor(self)

		@active = false

		update_status(@interface.sensor_status(address))
	end

	def update_status(status)
		@active = status[:active]
		puts self.to_s
	end

	def to_s
		"Sensor ##{@address}: active=#{@active}"
	end

end