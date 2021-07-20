using NumDisplay

println("Starting...")

d = DisplayBCD([27, 22, 10, 9], (7, 17, 4, 3, 2))
shutdown_mode_off(d)

println("write 0, 1, 2, 3")
sleep(3)
write_digit(d, UInt8(0), 1)
sleep(3)
write_digit(d, UInt8(1), 2)
sleep(3)
write_digit(d, UInt8(2), 3)
sleep(3)
write_digit(d, UInt8(3), 4)

sleep(3)
write_digit(d, UInt8(4), 1)
sleep(3)
write_digit(d, UInt8(5), 2)
sleep(3)
write_digit(d, UInt8(6), 3)
sleep(3)
write_digit(d, UInt8(7), 4)


sleep(10)
println("Stop.")
