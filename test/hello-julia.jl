using PiGPIOC

function send_16(spi, data::AbstractArray{UInt8})
    cstr = Cstring(pointer(data))
    ret = PiGPIOC.spiWrite(spi, cstr, 2)
    if ret < 0
        throw("spiWrite returns error with status: $ret")
    end

    nothing
end

function clear_all(spi)
    send_16(spi, [0b0000_0001, 0b0000_0000])
    send_16(spi, [0b0000_0010, 0b0000_0000])
    send_16(spi, [0b0000_0011, 0b0000_0000])
    send_16(spi, [0b0000_0100, 0b0000_0000])
    send_16(spi, [0b0000_0101, 0b0000_0000])
    send_16(spi, [0b0000_0110, 0b0000_0000])
    send_16(spi, [0b0000_0111, 0b0000_0000])
    send_16(spi, [0b0000_1000, 0b0000_0000])
end

println("Starting...")

if PiGPIOC.gpioInitialise() < 0
    throw("pigpio initialisation failed.")
else
    @info "pigpio initialised okay."
end

channel = 0
baud = 32*10^3
spiFlags = 0b0000000000000000000000
spi = PiGPIOC.spiOpen(channel, baud, spiFlags) # channel, rate, flag

# init
send_16(spi, [0b0000_1100, 0b0000_0001]) # shut down off (normal)
send_16(spi, [0b0000_1111, 0b0000_0000]) # display test off (normal)
send_16(spi, [0b0000_1011, 0b0000_0111]) # no scan limit
send_16(spi, [0b0000_1001, 0b0000_0000]) # decode on for digits 0-7

for i in 1:10
sleep(2)
clear_all(spi)

# H
send_16(spi, [0b0000_1000, 0b0011_0111])
# E
send_16(spi, [0b0000_0111, 0b0100_1111])
# L
send_16(spi, [0b0000_0110, 0b0000_1110])
# L
send_16(spi, [0b0000_0101, 0b0000_1110])
# O
send_16(spi, [0b0000_0100, 0b0111_1110])

sleep(2)
clear_all(spi)

# J
send_16(spi, [0b0000_1000, 0b0011_1100])
# U
send_16(spi, [0b0000_0111, 0b0011_1110])
# L
send_16(spi, [0b0000_0110, 0b0000_1110])
# I
send_16(spi, [0b0000_0101, 0b0011_0000])
# A
send_16(spi, [0b0000_0100, 0b0111_0111])

end

println("Stop.")
