require "serialport"

class P50XInterface

	def initialize(serial_device, baud_rate)
		@port = SerialPort.new(serial_device, baud_rate)
		@port.read_timeout = -1
	end

	def close
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
		option_bits |= 0x40 # always force, no reason holding up
		#option_bits |= 0x80 # should be se it any of f1-f4 is to be changed

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
		return if address >= 0x800
		address_low_bits = address & 0xFF
		second_byte = address >> 8
		second_byte |= 0x40 if (active)
		second_byte |= 0x80 if (color == :green)

		self.write("X\x90" << address_low_bits << second_byte)
		self.read(1)
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

	protected

	def write(data)
		string = ""
		data.each_char do |char|
			@port.write(char)
			string += " 0x#{char.getbyte(0).to_s(16)}"
			sleep(0.01)
		end
		puts ">>#{string}"
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
		prepare_response(response)
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
			if (response.length == 1 && response[0] > 0)
				break;
			end
		end
		prepare_response(response)
	end

	def prepare_response(response)
		string = ""
		response.each do |byte|
			string += " 0x#{byte.to_s(16)}"
		end
		puts "<<#{string}"
		return response[0] if response.length == 1
		return response
	end

	def locomotive_address_bytes(address)
		return [ 0, 0 ] if address >= 1000
		[
			address & 0xFF,
			address >> 8
		]
	end

	def turnout_address_bytes(address)

	end

end