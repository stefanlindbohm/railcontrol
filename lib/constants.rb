module Error
	# generic
	OK                         = 0x00
	BAD_PARAMETER              = 0x02

	# power errors
	POWER_IS_OFF               = 0x06

	# buffer errors
	LOCOMOTIVE_BUFFER_FULL     = 0x08
	TURNOUT_FIFO_FULL          = 0x09
	I2C_FIFO_FULL              = 0x10

	# locomotive errors
	LOCOMOTIVE_NOT_AVAILABLE   = 0x0A
	NO_SLOT_AVAILABLE          = 0x0B
	ILLEGAL_LOCOMOTIVE_ADDRESS = 0x0C
	LOCOMOTIVE_BUSY            = 0x0D

	# turnout errors
	ILLEGAL_TURNOUT_ADDRESS    = 0x0E

	# warnings
	TURNOUT_FIFO_ALMOST_FULL   = 0x40
	ACCEPTED_IN_HALT_MODE      = 0x41
	ACCEPTED_WHILE_POWER_OFF   = 0x42
end