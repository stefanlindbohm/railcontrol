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
		return if (address >= 1000)
		address_low_bits = address & 0xFF
		address_high_bits = address >> 8
		option_bits = 0
		#option_bits |= 0x01 if (options[:function1])
		#option_bits |= 0x02 if (options[:function2])
		#option_bits |= 0x04 if (options[:function3])
		#option_bits |= 0x08 if (options[:function4])
		option_bits |= 0x10 if (lights)
		option_bits |= 0x20 unless (direction == :reverse)
		option_bits |= 0x40 # always force, no reason holding up
		#option_bits |= 0x80 # should be se it any of f1-f4 is to be changed

		self.write("X\x80" << address_low_bits << address_high_bits << speed << option_bits)
		self.read(1)
	end

	def locomotive_status(address)
		self.write("X\x84" << address << 0)
		self.read(1)
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
		string = ""
		response.each do |byte|
			string += " 0x#{byte.to_s(16)}"
		end
		puts "<<#{string}"
		return response[0] if length == 1
		return response
	end

end