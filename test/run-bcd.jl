using NumDisplay

println("Starting...")

d = DisplayBCD([5, 6, 13, 19], (2, 3, 4, 17, 27))
sleep(3)

shutdown_mode_off(d)
sleep(3)

###

println("Low level method write_digit()...")

println("write 3210")
write_digit(d, UInt8(0), 1)
write_digit(d, UInt8(1), 2)
write_digit(d, UInt8(2), 3)
write_digit(d, UInt8(3), 4)

sleep(3)
println("write 7654")
write_digit(d, UInt8(4), 1)
write_digit(d, UInt8(5), 2)
write_digit(d, UInt8(6), 3)
write_digit(d, UInt8(7), 4)
sleep(3)

println("write ??98")
write_digit(d, UInt8(8), 1)
write_digit(d, UInt8(9), 2)
write_digit(d, UInt8(10), 3)
write_digit(d, UInt8(11), 4)
sleep(3)

println("write  ???")
write_digit(d, UInt8(12), 1)
write_digit(d, UInt8(13), 2)
write_digit(d, UInt8(14), 3)
write_digit(d, UInt8(15), 4)
sleep(3)

###

println("High level method write_number()...")

data = [nothing,6,6,6]
write_number(d, data)
println("$data\n")
sleep(3)

println("Maximal intensity 16")
set_intensity(d, 16)
sleep(3)

println("change intensity from 16 to 1")
for i in collect(16:(-1):1)
    set_intensity(d, i)
    println("$i/16")
    sleep(0.5)
end
sleep(3)

println("shutdown_mode_on()")
shutdown_mode_on(d)
sleep(3)

println("shutdown_mode_off()")
shutdown_mode_off(d)
sleep(3)

println("test_mode_on()")
test_mode_on(d)
sleep(3)

println("test_mode_off()")
test_mode_off(d)
sleep(3)

println("Stop.")
shutdown_mode_off(d)
