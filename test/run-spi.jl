using NumDisplay

println("Starting...")

d = DisplaySPI()
shutdown_mode_off(d)

###

println("High level method write_number()...")

data = [0,1,2,3,4,5,6,7]
write_number(d, data)
println("$data\n")
sleep(5)

data = [8,9,10,11,12,13,14,15]
write_number(d, data)
println("$data\n")
sleep(5)

data = [6,6,6,nothing,9,9,9,nothing]
write_number(d, data)
println("$data\n")
sleep(5)

write_number(d, data, 1)
println("$data with dot at 1\n")
sleep(3)

write_number(d, data, 2)
println("$data with dot at 2\n")
sleep(3)

write_number(d, data, 3)
println("$data with dot at 3\n")
sleep(3)

write_number(d, data, 4)
println("$data with dot at 4\n")
sleep(3)

data = 31415926
write_number(d, data, 8)
println("$data with dot at 8\n")
sleep(5)

println("High level method write_symbols()...")

data = [0b01001001, 0b01001001, 0b01001001, 0b01001001, 0b01001001, 0b01001001, 0b01001001, 0b01001001]
write_symbols(d, data)
println("$data\n")
sleep(5)

data = ['A', 'I', 'L', 'U', 'J']
write_symbols(d, data)
println("$data\n")
sleep(5)

data = "Hello Hi"
write_symbols(d, data)
println("$data\n")
sleep(5)

println("Stop.")
