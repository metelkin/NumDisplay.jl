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
    struct DisplayBCD <: DisplayNoBuffer
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
        common_cathode::Bool = false
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

- `common_cathod` : set `true` if you use common cathod display or `false` for common anode.
    This option inverts `digit_pins` or `sectors_pins` active states.
"""
function DisplayBCD(
    digits_pins::AbstractVector{Int},
    sectors_pins::Tuple{Int,Int,Int,Int,Int},
    scan_rate::Real = 800, # Hz
    common_cathode::Bool = false
)
    @assert 1 <= length(digits_pins) <= 8 "The package supports up to 8 digits, got $(length(digits_pins))"

    # for common anode
    inverted_digits::Bool = common_cathode
    inverted_sectors::Bool = !common_cathode

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

decode_mode(::DisplayBCD) = 0b11111111
