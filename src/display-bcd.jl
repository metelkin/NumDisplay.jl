#=
0. gpioWaveClear
1. gpioWaveAddGeneric ( gpioWaveAddNew, gpioWaveAddSerial )
2. gpioWaveCreate (gpioWaveCreatePad, )
3. gpioWaveTxSend (gpioWaveChain, )

gpioWaveTxAt
gpioWaveDelete
gpioWaveTxStop
=#

"""
    mutable struct DisplayBCD <: DisplayNoBuffer
        digits_pins::AbstractVector{Int}      # pin numbers to control digits: [LSD ... MSD]
        sectors_pins::Tuple{Int,Int,Int,Int,Int,Int,Int,Int}  # pin numbers for binary code: (d0,d1,d2,d3,-,-,-,DP)
        buffer::AbstractVector{UInt8}         # internal storage of digits values
        usDelay::Int                          # duration of period when digit is on
        inverted_digits::Bool                 # if digit pins states must be inverted, i.e. 1 means LOW pin state
        inverted_sectors::Bool                # if input pins and dp pin states must be inverted, i.e. 1 means LOW pin state
        intensity::Int                        # 16 max
        limit::Int
        test_mode::Bool
    end
"""
mutable struct DisplayBCD <: DisplayNoBuffer
    digits_pins::AbstractVector{Int}
    sectors_pins::Tuple{Int,Int,Int,Int,Int,Int,Int,Int}
    buffer::AbstractVector{UInt8}
    usDelay::Real
    inverted_digits::Bool
    inverted_sectors::Bool
    intensity::Int
    limit::Int
    test_mode::Bool
end

"""
    function DisplayBCD(
        digits_pins::AbstractVector{Int},
        sectors_pins::Tuple{Int,Int,Int,Int,Int}, # A, B, C, D, DP
        scan_rate::Real = 800,                    # Hz
        inverted_digits::Bool = false
        inverted_sectors::Bool = false
    )

Creates device representing numerical display with several digits under control of the BCD chip.
The number of display digits equal to `digits_pins` count.

## Arguments

- `digits_pins` : Vector of GPIO pin numbers connected to anode. The HIGH state means the digit is on. LOW means off.
    The first pin in array should manage the less significant digit.

- `sectors_pins` : Tuple of length 5 consisting of GPIO numbers representing the 4-bit code of a digit.
    The sequence of pins is the following: (d0, d1, d2, d3, DP).

- `scan_rate` : refresh rate of digits in Hz. 
    The digits in display are controlled by impulses of `digits_pins`. 
    This argument sets the time period for display of one digit.
    If `scan_rate=1000` the width will be recalculated as `1/1000 = 1e-3` second or `1e3` microsecond.
    The default value is 800 Hz.

- `inverted_digits` : 

- `inverted_sectors` :
"""
function DisplayBCD(
    digits_pins::AbstractVector{Int},
    sectors_pins::Tuple{Int,Int,Int,Int,Int},
    scan_rate::Real = 800, # Hz
    inverted_digits::Bool = false,
    inverted_sectors::Bool = false
)
    @assert 1 <= length(digits_pins) <= 8 "The package supports up to 8 digits, got $(length(digits_pins))"

    if PiGPIOC.gpioInitialise() < 0
        throw("pigpio initialisation failed.")
    else
        @info "pigpio initialised okay."
    end

    # set frequency
    # TODO: display real frequency
    min_rate = ceil(Int, 10^6 / PiGPIOC.gpioWaveGetMaxMicros())
    max_rate = 10^6 # based on minimal usDelay = 1 
    @assert min_rate <= scan_rate <= max_rate "Scan rate must be between $min_rate and $max_rate, got $scan_rate"
    usDelay = 10^6 / scan_rate # conversion to us

    # init pins
    PiGPIOC.gpioSetMode(digits_pins, PiGPIOC.PI_OUTPUT)
    PiGPIOC.gpioWrite(digits_pins, 0)
    PiGPIOC.gpioSetMode(sectors_pins, PiGPIOC.PI_OUTPUT)
    PiGPIOC.gpioWrite(sectors_pins, 0)

    buffer = fill(0b10001111, length(digits_pins)) # set empty display

    DisplayBCD(
        digits_pins,
        (sectors_pins[1], sectors_pins[2], sectors_pins[3], sectors_pins[4], -1, -1, -1, sectors_pins[5]),
        buffer,
        usDelay,
        inverted_digits,
        inverted_sectors,
        5,                   # default intensity
        length(digits_pins), # default limit,
        false
    )
end

decode(::DisplayBCD) = 0b00000000

# this function is not avalable for BCD displays
function decode_mode(d::DisplayBCD, decode::UInt8 = 0b1111_1111)
    @warn "`decode_mode` method doesn't work for DisplayBCD"
end

# generate test wave with all sectors are active and maximal intensity
function generate_test_wave(d::DisplayBCD)
    pulse = PiGPIOC.gpioPulse_t[]

    # set active state
    activePeriod = ceil(Int, d.usDelay)
    for i in 1:size(d)
        gpioOn = 0x0
        gpioOff = 0x0

        # digits
        for j in 1:size(d)
            if d.digits_pins[j] >= 0
                if xor(i == j, d.inverted_digits)
                    gpioOn |= 1 << d.digits_pins[j]
                else
                    gpioOff |= 1 << d.digits_pins[j]
                end
            end
        end

        # sectors
        value = 0b1000_1000 # representation of 8. = 0x1000
        for j in 1:8
            if d.sectors_pins[j] >= 0
                if xor(value % 2 == 1, d.inverted_sectors)
                    gpioOn |= 1 << d.sectors_pins[j]
                else
                    gpioOff |= 1 << d.sectors_pins[j]
                end
            end
            value >>= 1
        end
        
        push!(pulse, PiGPIOC.gpioPulse_t(gpioOn, gpioOff, activePeriod)) # on, off, usDelay
    end

    PiGPIOC.gpioWaveAddGeneric(size(d), pulse)
    wave_id = PiGPIOC.gpioWaveCreate()
    if wave_id < 0
        # return Upon success a wave id greater than or equal to 0 is returned, 
        # otherwise PI_EMPTY_WAVEFORM, PI_TOO_MANY_CBS, PI_TOO_MANY_OOL,
        # or PI_NO_WAVEFORM_ID
        throw("Error in 'PiGPIOC.gpioWaveCreate()' with code: $(wave_id)")
    end

    return wave_id
end