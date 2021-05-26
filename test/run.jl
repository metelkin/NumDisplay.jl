using NumDisplay

ind = DisplayBCD([27, 22, 10, 9], (2, 3, 4, 17))
sleep(1)

write_digit(ind, UInt8(0), 1)
sleep(1)
write_digit(ind, UInt8(1), 2)
sleep(1)
write_digit(ind, UInt8(2), 3)
sleep(1)
write_digit(ind, UInt8(3), 4)
sleep(1)

clean(ind)
sleep(1)

write_digit(ind, UInt8(4), 1)
sleep(1)
write_digit(ind, UInt8(5), 2)
sleep(1)
write_digit(ind, UInt8(6), 3)
sleep(1)
write_digit(ind, UInt8(7), 4)
sleep(1)

clean(ind)
sleep(1)

write_digit(ind, UInt8(8), 1)
sleep(1)
write_digit(ind, UInt8(9), 2)
sleep(1)
write_digit(ind, UInt8(10), 3)
sleep(1)
write_digit(ind, UInt8(11), 4)
sleep(1)

sleep(3)

stop(ind)

@info "writing  numbers"

write_number(ind, 0)
sleep(1)
write_number(ind, 1)
sleep(1)
write_number(ind, 22)
sleep(1)
write_number(ind, 333)
sleep(1)
write_number(ind, 4444)
sleep(1)
write_number(ind, 333)
sleep(1)
write_number(ind, 22)
sleep(1)
write_number(ind, 1)
sleep(1)
write_number(ind, 0)
sleep(1)

stop(ind)

@info "STOP"
