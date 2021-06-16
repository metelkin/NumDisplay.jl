
###

println("Low level methods")

decode_mode(d, 0b00000001)
println("decode_mode for digit 1 only\n")
sleep(3)

decode_mode(d)
println("decode_mode for all digits\n")
sleep(3)

decode_mode(d, 0b0)
println("decode_mode for none\n")
sleep(3)

println("change intensity")
for i in 1:16
    set_intensity(d, i)
    println("$i/16")
    sleep(0.5)
end
for i in collect(16:(-1):1)
    set_intensity(d, i)
    println("$i/16")
    sleep(0.5)
end
sleep(1)

println("change limit")
for i in collect(4:(-1):1)
    set_limit(d, i)
    println("$i/4")
    sleep(0.5)
end

for i in 1:4
    set_limit(d, i)
    println("$i/4")
    sleep(0.5)
end
sleep(1)

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

println("switch to decode and set 3,3,3,3 at positions 4,3,2,1")
decode_mode(d)
write_digit(d, UInt8(3), 4)
sleep(1)
write_digit(d, UInt8(3), 3)
sleep(1)
write_digit(d, UInt8(3), 2)
sleep(1)
write_digit(d, UInt8(3), 1)
sleep(1)
