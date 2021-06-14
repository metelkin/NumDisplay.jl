using NumDisplay

ind = DisplayDirect([27, 22, 10, 9], (11, 2, 3, 4, 17, 27, 22, 10))
shutdown_mode_off(ind)
sleep(1)

write_digit(ind, UInt8(0), 1) # ___0
sleep(1)
write_digit(ind, UInt8(1), 2) # __10
sleep(1)
write_digit(ind, UInt8(2), 3) # _210
sleep(1)
write_digit(ind, UInt8(3), 4) # 3210
sleep(1)

#clean(ind)                    # ____
sleep(1)

write_digit(ind, UInt8(4), 1) # ___4
sleep(1)
write_digit(ind, UInt8(5), 2) # __54
sleep(1)
write_digit(ind, UInt8(6), 3) # _654
sleep(1)
write_digit(ind, UInt8(7), 4) # 7654
sleep(1)

#clean(ind)                    # ____
sleep(1)

write_digit(ind, UInt8(8), 1) # ___8
sleep(1)
write_digit(ind, UInt8(9), 2) # __98
sleep(1)
write_digit(ind, UInt8(10), 3) # _?98
sleep(1)
write_digit(ind, UInt8(11), 4) # ??98
sleep(1)
# clean(ind)                    # ____

#=
@info "writing  numbers"

write_number(ind, 0)      # ___0
sleep(1)
write_number(ind, 1)      # ___1
sleep(1)
write_number(ind, 22)     # __22
sleep(1)
write_number(ind, 333)    # _333
sleep(1)
write_number(ind, 4444)   # 4444
sleep(1)
write_number(ind, 333)    # _333
sleep(1)
write_number(ind, 22)     # __22
sleep(1)
write_number(ind, 1)      # ___1
sleep(1)
write_number(ind, 0)      # ___0
sleep(1)

stop(ind)                 # ____
=#
@info "STOP"
