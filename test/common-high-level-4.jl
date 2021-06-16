
###

println("High level method write_number()...")

data = [0,1,2,3]
write_number(d, data)
println("$data\n")
sleep(3)

data = [4,5,6,7]
write_number(d, data)
println("$data\n")
sleep(3)

data = [8,9,10,11]
write_number(d, data)
println("$data\n")
sleep(3)

data = [6,6,6,nothing]
write_number(d, data)
println("$data\n")
sleep(3)

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

data = 3141
write_number(d, data, 4)
println("$data with dot at 4\n")
sleep(3)

println("High level method write_symbols()...")

data = [0b01001001, 0b01001001, 0b01001001, 0b01001001]
write_symbols(d, data)
println("$data\n")
sleep(3)

data = ['I', 'L', 'U', 'J']
write_symbols(d, data)
println("$data\n")
sleep(3)

data = "Hell"
write_symbols(d, data)
println("$data\n")
sleep(3)
