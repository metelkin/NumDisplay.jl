using NumDisplay

println("Starting...")

d = DisplayBCD([5, 6, 13, 19], (2, 3, 4, 17, 27))
sleep(3)

shutdown_mode_off(d)
sleep(3)

println("write 3210")
write_digit(d, UInt8(0), 1)
write_digit(d, UInt8(1), 2)
write_digit(d, UInt8(2), 3)
write_digit(d, UInt8(3), 4)

sleep(3)
println("write 3214")
write_digit(d, UInt8(4), 1)
sleep(3)
println("write 3254")
write_digit(d, UInt8(5), 2)
sleep(3)
println("write 3654")
write_digit(d, UInt8(6), 3)
sleep(3)
println("write 7654")
write_digit(d, UInt8(7), 4)

sleep(10)
println("Stop.")
