require "./lib/railcontrol"

interface = P50XInterface.new("/dev/cu.PL2303-003013FA", 19200)

railway = Railway.new(interface)
steam_loco = Locomotive.new(railway, 78)
sj_loco = Locomotive.new(railway, 36)

turnout1 = Turnout.new(railway, 1)
turnout2 = Turnout.new(railway, 3)

sleep(10)
sj_loco.lights = true
sleep(1)
turnout1.color = :red
turnout2.color = :red
sj_loco.speed = 100
sleep(20)
sj_loco.speed = 0
sleep(10)
sj_loco.lights = false

interface.close