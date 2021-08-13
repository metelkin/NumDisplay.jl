"""
    mutable struct DisplayDirect <: DisplayNoBuffer
        digits_pins::AbstractVector{Int}             # pins' numbers to control digit: [LSD ... MSD]
        sectors_pins::Tuple{Int,Int,Int,Int,Int,Int,Int,Int} # pins' number to control sectors: (g,f,e,d,c,b,a,DP) | (d0,d1,d2,d3,-,-,-,DP)
        buffer::AbstractVector{UInt8}                # storage for current digit values
        usDelay::Real                                # duration of one active digit
        inverted_digits::Bool                        # if digit pins states must be inverted, i.e. 1 means LOW pin state
        inverted_sectors::Bool                       # if sectors pins' states must be inverted, i.e. 1 means LOW pin state
        decode_mode::UInt8                           # current decode mode for digits, 0b00000001 - only first digit is in decode mode
        intensity::Int                               # value from 1 to 16, brightness controlled by pulse-width
        limit::Int                                   # current number of digits to show
    end
"""
mutable struct DisplayDirect <: DisplayNoBuffer
    digits_pins::AbstractVector{Int}
    sectors_pins::Tuple{Int,Int,Int,Int,Int,Int,Int,Int}
    buffer::AbstractVector{UInt8}
    usDelay::Real
    inverted_digits::Bool
    inverted_sectors::Bool
    decode_mode::UInt8 # can manage only 8 digits, 1 bit per digit
    intensity::Int # 16 max
    limit::Int
    test_mode::Bool
end

"""
    function DisplayDirect(
        digits_pins::AbstractVector{Int},
        sectors_pins::Tuple{Int,Int,Int,Int,Int,Int,Int,Int};
        scan_rate::Real = 800, # Hz
        inverted_digits::Bool = false,
        inverted_sectors::Bool = false
    )

Creates numerical display device controlled directly with the RaspberryPi pins.
The number of display digits equal to `digits_pins` count.
`DisplayDirect` stores its states in internal `buffer` and creates the pulse-width wave
 to show digits on a physical device.

Initial state of display:
- **shutdown mode** on. Use method `shutdown_mode_off()` to activate the display before the first use.
- **test mode** off.
- **decode mode** is on for all digits.
- **limit** value is equal to all available digits, see `size()`
- **intensity** = 5
- `buffer` is zero for all digits. 

## Arguments

- `digits_pins` : Vector of GPIO pin numbers connected to common anode or cathode.
    The first pin in array manages the less significant digit (LSD) of display.
    The value `-1` is also possible here which means that the digit will not be used.

- `sectors_pins` : Tuple of length 8 consisting of GPIO numbers controlling
    the states of 8 sectors.
    The sequence of pins is the following: (g, f, e, d, c, b, a, DP).
    This corresponds to the sequence of bits (starting from most significant) in `buffer`.
    The value `-1` is also possible here which means that the pin will not be used.

- `scan_rate` : refresh rate of digits in Hz. 
    The digits in display are controlled by impulses of `digits_pins`. 
    This argument sets the time period for display of one digit.
    If `scan_rate=1000` the width will be recalculated as `1/1000 = 1e-3` second or `1e3` microsecond.
    The default value is 800 Hz.

- `inverted_digits` : This option inverts `digit_pins` active states.

- `inverted_sectors` : This option inverts `sectors_pins` active states.
"""
function DisplayDirect(
    digits_pins::AbstractVector{Int},
    sectors_pins::Tuple{Int,Int,Int,Int,Int,Int,Int,Int};
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

    buffer = fill(0b00000000, length(digits_pins))

    return DisplayDirect(
        digits_pins,
        sectors_pins,
        buffer,
        usDelay,
        inverted_digits,
        inverted_sectors,
        0b11111111,          # decode_mode
        5,                   # default intensity
        length(digits_pins), # default limit,
        false
    )
end

decode(::DisplayDirect) = d.decode_mode

# generate test wave with all sectors are active and maximal intensity
function generate_test_wave(d::DisplayDirect)
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
        for j in 1:8
            if d.sectors_pins[j] >= 0
                if !d.inverted_sectors
                    gpioOn |= 1 << d.sectors_pins[j]
                else
                    gpioOff |= 1 << d.sectors_pins[j]
                end
            end
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

# this function is not avalable for BCD displays
function decode_mode(d::DisplayDirect, decode::UInt8 = 0b1111_1111)
    d.decode_mode = decode
    update(d)
end
