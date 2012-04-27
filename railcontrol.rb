require "./lib/railcontrol"

interface = P50XInterface.new("/dev/cu.PL2303-003013FA", 19200)

railway = Railway.new(interface)
steam_loco = Locomotive.new(railway, 78)
sj_loco = Locomotive.new(railway, 36)

turnout1 = Turnout.new(railway, 1)
turnout2 = Turnout.new(railway, 3)

#interface.locomotive(78, 0, :forward, false)
puts steam_loco
puts sj_loco

interface.close