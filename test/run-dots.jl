using NumDisplay

ind = DisplayBCD([27, 22, 10, 9], (2, 3, 4, 17), 11)
sleep(1)

write_dp(ind, UInt8(1), 1) # ____.
sleep(1)
write_dp(ind, UInt8(1), 2) # ___._.
sleep(1)
write_dp(ind, UInt8(1), 3) # __._._.
sleep(1)
write_dp(ind, UInt8(1), 4) # _._._._.
sleep(1)

clean(ind)                    # ____
sleep(1)

@info "writing  numbers"

write_number(ind, 0, 1)      # ___0.
sleep(1)
write_number(ind, 1, 2)      # ___.1
sleep(1)
write_number(ind, 22, 2)     # __2.2
sleep(1)

stop(ind)                 # ____

@info "STOP"
