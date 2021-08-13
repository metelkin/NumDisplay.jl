#=
	        MISO	MOSI	SCLK	CE0	CE1	CE2
Main SPI	9	    10	    11	    8	7	-
Aux  SPI	19	    20	    21	    18	17	16
=#
"""
    struct DisplaySPI <: AbstractNumDisplay
        handle::Int
    end
"""
struct DisplaySPI <: AbstractNumDisplay
    handle::Int
end

"""
    function DisplaySPI(;
        spi::Int = 0,
        channel::Int = 0,
        boud::Int = 32*10^3
    )

Creates device that refers to numerical display integrated with SPI chip.

## Arguments

- `spi` : value 0 or 1 to use main or auxilary RaspberryPi's SPI controller. Default is main.

- `channel` : number of CE port: 0, 1 for the main SPI or 0, 1, 2 for the auxilary one. Default is 0.

- `boud` : data transfer rate for SPI, bits per second. Must be from 32kHz to 10MHz.
"""
function DisplaySPI(;
    spi::Int = 0,
    channel::Int = 0,
    boud::Int = 32*10^3 # bits per second
)
    # theoretical spi max boud = 125 MHz, practical max = 30 MHz
    # chip max boud = 10 MHz
    @assert 32*10^3 <= boud <= 10*10^6 "boud must be 32kHz-10Mhz, got $boud"

    @assert 0 <= spi <= 1 "spi number must be 0 or 1, got $spi"

    if PiGPIOC.gpioInitialise() < 0
        throw("pigpio initialisation failed.")
    else
        println("pigpio initialised okay.")
    end

    # b  b  b  b  b  b  R  T  n  n  n  n  W  A u2 u1 u0 p2 p1 p0  m  m
    # default but main or auxiliary
    spiFlags = spi << 8 # set to position 8

    # set spi num here
    handle = PiGPIOC.spiOpen(channel, boud, spiFlags)
    if handle < 0
        throw("spiOpen returns error with status: $spi")
    end

    DisplaySPI(handle)
end

function spiWrite_bytes(d::DisplaySPI, data::AbstractArray{UInt8})
    bytes_count = length(data)
    cs = Cstring(pointer(data))
    ret = PiGPIOC.spiWrite(d.handle, cs, bytes_count)
    if ret < 0
        throw("spiWrite returns error with status: $ret")
    end

    nothing
end


# scan rate = 800 Hz (500-1300) from chip docs
scan_rate(::DisplaySPI) = 800

size(d::DisplaySPI) = 8

### low-level operations

function decode_mode(d::DisplaySPI, decode::UInt8 = 0b1111_1111)
    data = [0b0000_1001, decode]
    spiWrite_bytes(d, data)
end

function set_intensity(d::DisplaySPI, intensity::Int = 16)
    @assert 1 <= intensity <= 16 "intensity must be between 1 and 16, got $intensity"

    data = [0b0000_1010, UInt8(intensity - 1)]
    spiWrite_bytes(d, data)
end

function set_limit(d::DisplaySPI, limit::Int = 8)
    @assert 1 <= limit <= 8 "limit must be between 1 and 8, got $limit"

    data = [0b0000_1011, UInt8(limit - 1)]
    spiWrite_bytes(d, data)
end

function shutdown_mode_on(d::DisplaySPI)
    data = [0b0000_1100, 0b0000_0000]
    spiWrite_bytes(d, data)
end

function shutdown_mode_off(d::DisplaySPI)
    data = [0b0000_1100, 0b0000_0001]
    spiWrite_bytes(d, data)
end

function test_mode_on(d::DisplaySPI)
    data = [0b0000_1111, 0b0000_0001]
    spiWrite_bytes(d, data)
end

function test_mode_off(d::DisplaySPI)
    data = [0b0000_1111, 0b0000_0000]
    spiWrite_bytes(d, data)
end

function write_digit(d::DisplaySPI, value::UInt8, position::Int)
    @assert 1 <= position <= 8 "position must be between 1 and 8, got $position"

    data = [UInt8(position), value]
    spiWrite_bytes(d, data)
end
