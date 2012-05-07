require "serialport"

class P50XInterface

	attr_accessor :delegate

	def initialize(serial_device, baud_rate, delegate=nil)
		@port = SerialPort.new(serial_device, baud_rate)
		@port.read_timeout = 100
		@delegate = delegate
		@sensors = []
		@running = true
		self.update_all_sensors
	end

	def event_run
		while (@running)

		end
	end

	def close
		@running = false
		# wait for event thread to stop
		@port.close
	end

	def start
		self.write("X\xA7")
		self.read(1)
	end

	def stop
		self.write("X\xA6")
		self.read(1)
	end

	def halt
		self.write("X\xA5")
		self.read(1)
	end

	def locomotive(address, speed, direction, lights)
		address_bytes = locomotive_address_bytes(address)
		option_bits = 0
		#option_bits |= 0x01 if (options[:function1])
		#option_bits |= 0x02 if (options[:function2])
		#option_bits |= 0x04 if (options[:function3])
		#option_bits |= 0x08 if (options[:function4])
		option_bits |= 0x10 if (lights)
		option_bits |= 0x20 unless (direction == :reverse)
		option_bits |= 0x40 # force even when controlled elsewhere
		#option_bits |= 0x80 # should be set it any of f1-f4 is to be changed

		self.write("X\x80" << address_bytes[0] << address_bytes[1] << speed << option_bits)
		self.read(1)
	end

	def locomotive_status(address)
		address_bytes = locomotive_address_bytes(address)
		self.write("X\x84" << address_bytes[0] << address_bytes[1])
		status = self.read_unless_initial_error_byte(4)
		return { } if (status[0] > 0)
		{
			speed:     status[1],
			direction: status[2] & 0x20 == 0x20 ? :forward : :reverse,
			lights:    status[2] & 0x10 == 0x10
		}
	end

	def locomotive_dispatch(address)
		# i've got no idea what effect this has
		address_bytes = locomotive_address_bytes(address)
		self.write("X\x83" << address_bytes[0] << address_bytes[1])
		self.read(1)
	end

	def locomotive_configuration(address)
		address_bytes = locomotive_address_bytes(address)
		self.write("X\x85" << address_bytes[0] << address_bytes[1])
		response = self.read_unless_initial_error_byte(5)
		return { } if (response[0] > 0)
		protocol = case response[1]
		    when 0
			    :maerklin
		    when 1
			    :sx
		    when 2
			    :dcc
		    when 3
			    :fmz
	    end
		{
			protocol: protocol,
			speed_steps: response[2]
		}
	end

	def turnout(address, color, active)
		address_bytes = turnout_address_bytes(address)
		second_byte = address_bytes[1]
		second_byte |= 0x40 if (active)
		second_byte |= 0x80 if (color == :green)

		self.write("X\x90" << address_bytes[0] << second_byte)
		self.read(1)
	end

	def turnout_status(address)
		address_bytes = turnout_address_bytes(address)
		self.write("x\x94" << address_bytes[0] << address_bytes[1])
		status = self.read_unless_initial_error_byte(2)
		return { } if status[0] > 0
		{
			color: status[1] & 0x04 == 0x04 ? :green : :red
		}
	end

	def sensor_status(address)
		{
			active: address > 0 && @sensors.length >= address && @sensors[address - 1] ? true : false
		}
	end

	def status
		self.write("X\xA2")
		status = self.read(1)
		{
			stop:                 status & 0x01 == 0x01,
			go:                   status & 0x02 == 0x02,
			hot:                  status & 0x04 == 0x04,
			power:                status & 0x08 == 0x08,
			halt:                 status & 0x10 == 0x10,
			external_i2c_present: status & 0x20 == 0x20,
			voltage_regulation:   status & 0x40 == 0x40
		}
	end

	def update_all_sensors
		@sensors.clear
		self.write("X\x99")
		self.read(1)
		self.process_sensor_events
	end

	def process_events
		self.write("X\xC8")
		response = []
		done = false
		while (!done)
			data = @port.read
			if (data.length > 0)
				data.each_byte do |byte|
					response.push(byte)
					unless (byte & 0x80 == 0x80)
						done = true
						break
					end
				end
			end
		end
		if (response[0] & 0x01 == 0x01)
			self.process_locomotive_events
		end
		if (response[0] & 0x02 == 0x02)
			puts "IR event occurred"
		end
		if (response[0] & 0x04 == 0x04)
			self.process_sensor_events
		end
		if (response[0] & 0x08 == 0x08)
			puts "Power off has occurred"
		end
		if (response[0] & 0x10 == 0x10)
			puts "Reserved turnout change attempt occurred"
		end
		if (response[0] & 0x20 == 0x20)
			self.process_turnout_events
		end
		if (response.length > 1)
			if (response[1] & 0x01 == 0x01)
				puts "Short circuit reported by external booster"
			end
			if (response[1] & 0x02 == 0x02)
				puts "Short circuit reported on Lokmaus bus"
			end
			if (response[1] & 0x04 == 0x04)
				puts "Short circuit reported on internal booster"
			end
			if (response[1] & 0x08 == 0x08)
				puts "Short circuit reported on DCC booster C/D lines, LocoNet B connector or on programming track"
			end
			if (response[1] & 0x10 == 0x10)
				puts "Leak between programming track and rest of layout occurred"
			end
			if (response[1] & 0x20 == 0x20)
				puts "Intellibox is overheating!"
			end
			if (response[1] & 0x40 == 0x40)
				puts self.status
			end
			if (response.length > 2)
				if (response[2] & 0x01 == 0x01)
					puts "Programming track event occurred"
				end
				if (response[2] & 0x02 == 0x02)
					puts "RS-232 receive overflow"
				end
				if (response[2] & 0x04 == 0x04)
					puts "Undocumented memory event occurred :s"
				end
				if (response[2] & 0x08 == 0x08)
					puts "Undocumented locomotive take/release event occurred :s"
				end
				if (response[2] & 0x10 == 0x10)
					puts "External voltage is in contact with the rails"
				end
			end
		end
	end

	def process_locomotive_events
		self.write("X\xC9")
		self.read_iterative(0x80, 5).each do |locomotive_bytes|
			address = (locomotive_bytes[3] & 0b111111) << 8 | locomotive_bytes[2]
			status = {
				speed:     locomotive_bytes[0],
				direction: locomotive_bytes[3] & 0x80 == 0x80 ? :forward : :reverse,
				lights:    locomotive_bytes[3] & 0x40 == 0x40
			}
			@delegate.handle_locomotive_event(address, status) if @delegate.respond_to?(:handle_locomotive_event)
		end
	end

	def process_turnout_events
		self.write("X\xCA")
		self.read_counted(2).each do |turnout_bytes|
			address = (turnout_bytes[1] & 0b111) << 8 | turnout_bytes[0]
			status = {
				address: address,
				color: turnout_bytes[1] & 0x80 == 0x80 ? :green : :red,
				active: turnout_bytes[1] & 0x40 == 0x40
			}
			@delegate.handle_turnout_event(address, status) if @delegate.respond_to?(:handle_turnout_event)
		end
	end

	def process_sensor_events
		self.write("X\xCB")
		self.read_iterative(0, 3).each do |group_bytes|
			group_address = group_bytes[0]
			status_bytes = [ group_bytes[1], group_bytes[2] ]
			start_address = (group_address - 1) * 16

			status_bytes.each_index do |i|
				8.times do |sensor|
					bit = 0x80 >> sensor
					address = start_address + 8*i + sensor
					state = status_bytes[i] & bit == bit
					if (@sensors.length >= i && @sensors[address] != state)
						status = {
							active: state
						}
						@delegate.handle_sensor_event(address, status) if @delegate.respond_to?(:handle_sensor_event)
					end
					@sensors[address] = state
				end
			end
		end
	end

	protected

	def write(data)
		data.each_char do |char|
			@port.write(char)
			sleep(0.01)
		end
	end

	def read(length)
		response = []
		return response if length <= 0
		while (response.length < length)
			data = @port.read
			if (data.length > 0)
				data.each_byte do |byte|
					response.push(byte)
				end
			end
		end
		response.length == 1 ? response[0] : response
	end

	def read_unless_initial_error_byte(length)
		response = []
		return response if length <= 0
		while (response.length < length)
			data = @port.read
			if (data.length > 0)
				data.each_byte do |byte|
					response.push(byte)
				end
			end
			if (response.length == 1 && self.is_error_byte(response[0]))
				break
			end
		end
		response
	end

	def read_iterative(stop_byte, element_length)
		elements = []
		current_element = nil
		done = false
		while (!done)
			data = @port.read
			if (data.length > 0)
				data.each_byte do |byte|
					if ((current_element.nil? || current_element.length == 0) && byte == stop_byte)
						done = true
						break
					end
					current_element = [] if (current_element.nil?)
					current_element.push(byte)
					if (current_element.length >= element_length)
						elements.push(current_element)
						current_element = nil
					end
				end
			end
		end
		elements
	end

	def read_counted(element_length)
		length = nil
		elements = []
		current_element = nil
		done = false
		while (!done)
			data = @port.read
			if (data.length > 0)
				data.each_byte do |byte|
					if (length.nil?)
						length = byte
					else
						current_element = [] if (current_element.nil?)
						current_element.push(byte)
						if (current_element.length >= element_length)
							elements.push(current_element)
							current_element = nil
						end
					end
					if (elements.length >= length)
						done = true
						break
					end
				end
			end
		end
		elements
	end

	def is_error_byte(byte)
		if (byte == Error::OK || byte >= 0x40)
			false
		else
			true
		end
	end

	def locomotive_address_bytes(address)
		return [ 0, 0 ] if address >= 1000
		[
			address & 0xFF,
			address >> 8
		]
	end

	def turnout_address_bytes(address)
		return [ 0, 0 ] if address >= 0x800
		[
			address & 0xFF,
			address >> 8
		]
	end

end