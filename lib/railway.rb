class Railway

	def initialize(interface)
		@interface = interface
		@locomotives = []
		@turnouts = []
	end

	def register_locomotive(locomotive)
		@locomotives.push(locomotive)
		@interface
	end

	def register_turnout(turnout)
		@turnouts.push(turnout)
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

end