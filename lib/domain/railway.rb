class Railway

	def initialize(interface)
		@interface = interface
		@interface.delegate = self
		@locomotives = {}
		@turnouts = {}
		@sensors = {}
	end

	def register_locomotive(locomotive)
		@locomotives[locomotive.address] = locomotive
		@interface
	end

	def register_turnout(turnout)
		@turnouts[turnout.address] = turnout
		@interface
	end

	def register_sensor(sensor)
		@sensors[sensor.address] = sensor
		@interface
	end

	def start
		@interface.start
	end

	def halt
		@interface.halt
	end

	def stop
		@interface.stop
	end

	def handle_locomotive_event(address, status)
		if (@locomotives.has_key?(address))
			@locomotives[address].update_status(status)
		end
	end

	def handle_turnout_event(address, status)
		if (@turnouts.has_key?(address))
			@turnouts[address].update_status(status)
		end
	end

	def handle_sensor_event(address, status)
		if (@sensors.has_key?(address))
			@sensors[address].update_status(status)
		end
	end

end