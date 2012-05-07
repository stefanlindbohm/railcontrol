require "./lib/railcontrol"

puts "Creating interface"
interface = P50XInterface.new("/dev/cu.PL2303-001013FA", 19200)

puts "Creating domain stuff"
railway = Railway.new(interface)
steam_loco = Locomotive.new(railway, 78)
sj_loco = Locomotive.new(railway, 36)
turnout1 = Turnout.new(railway, 1)
turnout2 = Turnout.new(railway, 2)

#interface.locomotive(78, 0, :forward, false)
puts steam_loco
puts sj_loco
puts turnout1
puts turnout2

#puts interface.sensor_status(1)

#10.times do
#	turnout1.toggle
#	sleep(0.2)
#	turnout2.toggle
#	sleep(0.2)
#end

600.times do
	interface.process_events
	sleep(0.1)
end

interface.close