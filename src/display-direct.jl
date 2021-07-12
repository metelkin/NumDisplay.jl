"""
    mutable struct DisplayDirect <: AbstractNumDisplay
        digits_pins::AbstractVector{Int}              # pins' numbers to control digit
        sectors_pins::Tuple{Int,Int,Int,Int,Int,Int,Int,Int} # pins' number to control sectors: DP a b c d e f g
        buffer::AbstractVector{UInt8}                # storage for current digit values
        usDelay::Real                                # duration of one active digit
        inverted_digits::Bool                        # if digit pins states must be inverted, i.e. 1 means LOW pin state
        inverted_sectors::Bool                       # if sectors pins' states must be inverted, i.e. 1 means LOW pin state
        decode_mode::UInt8                           # current decode mode for digits, 0b00000001 - only first digit is in decode mode
        intensity::Int                               # value from 1 to 16, brightness controlled by pulse-width
        limit::Int                                   # current number of digits to show
    end
"""
mutable struct DisplayDirect <: AbstractNumDisplay
    digits_pins::AbstractVector{Int}
    sectors_pins::Tuple{Int,Int,Int,Int,Int,Int,Int,Int} # DP a b c d e f g
    buffer::AbstractVector{UInt8}
    usDelay::Real
    inverted_digits::Bool
    inverted_sectors::Bool
    decode_mode::UInt8
    intensity::Int # 16 max
    limit::Int
end

"""
    function DisplayDirect(
        digits_pins::AbstractVector{Int},
        sectors_pins::Tuple{Int,Int,Int,Int,Int,Int,Int,Int};
        scan_rate::Real = 800, # Hz
        common_cathode::Bool = false
    )

Creates numerical display device controlled directly with the RaspberryPi pins.
The number of display digits equal to `digits_pins` count.
`DisplayDirect` stores its states in internal `buffer` and creates the pulse-width wave
 to show digits on a physical device.

Initial state of display:
- **shutdown mode** on. Use method `shutdown_mode_off()` to activate the display before the first use.
- **test mode** off.
- **decode mode** off for all digits.
- **limit** value is equal to all available digits, see `size()`
- **intensity** = 5
- `buffer` is zero for all digits. 

## Arguments

- `digits_pins` : Vector of GPIO pin numbers connected to common anode or cathode.
    The first pin in array manages the less significant digit of display.
    The value `-1` is also possible here which means that the digit will not be used.
- `sectors_pins` : Tuple of length 8 consisting of GPIO numbers controlling
    the states of 8 sectors.
    The sequence of pins is the following: DP (dot), A, B, C, D, E, F, G.
    This corresponds to the sequence of bits (starting from most significant) in `buffer`.
    The value `-1` is also possible here which means that the sector will not be used.
- `scan_rate` : refresh rate of digits in Hz. 
    The digits in display are controlled by impulses of `digits_pins`. 
    This argument sets the time period for display of one digit.
    If `scan_rate=1000` the width will be recalculated as `1/1000 = 1e-3` second or `1e3` microsecond.
    The default value is 800 Hz.
- `common_cathod` : set `true` if you use common cathod display or `false` for common anode.
    This option inverts `digit_pins` or `sectors_pins` states.
"""
function DisplayDirect(
    digits_pins::AbstractVector{Int},
    sectors_pins::Tuple{Int,Int,Int,Int,Int,Int,Int,Int};
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

    buffer = fill(0b00000000, length(digits_pins))

    return DisplayDirect(
        digits_pins,
        sectors_pins,
        buffer,
        usDelay,
        inverted_digits,
        inverted_sectors,
        0b00000000,         # decode_mode
        5,                  # default intensity
        length(digits_pins) # default limit
    )
end

scan_rate(d::DisplayDirect) = ceil(Int, 10^6 / d.usDelay) # Hz

size(d::DisplayDirect) = length(d.digits_pins)

# update wave based on buffer
function generate_wave(d::DisplayDirect)
    # create new wave based on d.buffer
    # number of pulses is equal to limit
    pulse = PiGPIOC.gpioPulse_t[]
    
    # set pause after each blink
    inactivePeriod = ceil(Int, d.usDelay * (1 - d.intensity / 16))
    gpioOffPause = 0x0
    gpioOnPause = 0x0
    for j in 1:d.limit
        if d.digits_pins[j] >= 0
            if d.inverted_digits
                gpioOnPause |= 1 << d.digits_pins[j]
            else
                gpioOffPause |= 1 << d.digits_pins[j] # turn off all digit pins 
            end
        end
    end

    # set active state
    activePeriod = ceil(Int, d.usDelay * d.intensity / 16)
    for i in 1:d.limit
        gpioOn = 0x0
        gpioOff = 0x0

        # digits
        for j in 1:d.limit
            if d.digits_pins[j] >= 0
                if xor(i == j, d.inverted_digits)
                    gpioOn |= 1 << d.digits_pins[j]
                else
                    gpioOff |= 1 << d.digits_pins[j]
                end
            end
        end
        
        # if decode mode than 1
        decode_i = (d.decode_mode >> (i - 1)) % 2

        # sectors
        buffer_i = d.buffer[i]
        if decode_i == 0
            value = buffer_i
        else
            value = NUM_TRANSLATOR[buffer_i % 0b00010000] # get 4 least significant bits
            dp_state = buffer_i >> 7
            value += dp_state << 7
        end

        for j in 8:(-1):1
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
        push!(pulse, PiGPIOC.gpioPulse_t(gpioOnPause, gpioOffPause, inactivePeriod))
    end

    PiGPIOC.gpioWaveAddGeneric(d.limit * 2, pulse)
    wave_id = PiGPIOC.gpioWaveCreate()
    if wave_id < 0
        # return Upon success a wave id greater than or equal to 0 is returned, 
        # otherwise PI_EMPTY_WAVEFORM, PI_TOO_MANY_CBS, PI_TOO_MANY_OOL,
        # or PI_NO_WAVEFORM_ID
        throw("Error in 'PiGPIOC.gpioWaveCreate()' with code: $(wave_id)")
    end

    return wave_id
end

"""
    function update(d::DisplayDirect)

Generates a sequence of pulses based on buffer, decode_mode, intensity, limit, and runs pulses repeatedly.
The function is used internally after buffer and modes changes.
If a display is in test mode or shutdown mode, the function does nothing. 
"""
function update(d::DisplayDirect)
    if PiGPIOC.gpioWaveTxBusy() == 1
        wave_id = generate_wave(d)
        run_wave(wave_id)
    end
end

function shutdown_mode_off(d::DisplayDirect)
    # do nothing in normal mode
    if PiGPIOC.gpioWaveTxBusy() == 0
        wave_id = generate_wave(d)
        run_wave(wave_id)
    end
end

function shutdown_mode_on(d::DisplayDirect)
    # stop current wave
    PiGPIOC.gpioWaveTxStop()
        
    # clear pins
    PiGPIOC.gpioWrite(d.digits_pins, 0)
    PiGPIOC.gpioWrite(d.sectors_pins, 0)
end

function test_mode_off(d::DisplayDirect)
    # do nothing in normal mode
    if PiGPIOC.gpioWaveTxBusy() == 0
        wave_id = generate_wave(d)
        run_wave(wave_id)
    end
end

function test_mode_on(d::DisplayDirect)
    # stop current wave
    PiGPIOC.gpioWaveTxStop()

    # clear pins
    PiGPIOC.gpioWrite(d.digits_pins, d.inverted_digits ? 0 : 1) # inverted_digits = false
    PiGPIOC.gpioWrite(d.sectors_pins, d.inverted_sectors ? 0 : 1) # inverted_sectors = true
end

function set_limit(d::DisplayDirect, limit::Int = size(d))
    @assert 1 <= limit <= size(d) "limit must be between 1 and $(size(d)), got $limit"
    d.limit = limit

    update(d)
    # set empty states
    pins_to_free = (d.limit+1):size(d)
    PiGPIOC.gpioWrite(d.digits_pins[pins_to_free], !d.inverted_digits ? 0 : 1)
end

function decode_mode(d::DisplayDirect, decode::UInt8 = 0b1111_1111)
    d.decode_mode = decode
    update(d)
end

function set_intensity(d::DisplayDirect, intensity::Int = 16)
    @assert 1 <= intensity <= 16 "intensity must be between 1 and 16, got $intensity"
    d.intensity = intensity
    
    update(d)
end

function write_digit(
    d::DisplayDirect,
    value::UInt8,
    position::Int
)
    @assert 1 <= position <= 8 "position must be between 1 and 8, got $position"
    d.buffer[position] = value

    update(d)
end

#=
function write_number(
    indicator::DisplayDirect,
    digit_vector::AbstractArray{Int}, # digit from 0 to 9
    dp_position::Int
)
    # TODO: check digit_vector
    l = length(digit_vector)
    for i in 1:length(indicator.digits_pins)
        if i > l || digit_vector[i] >= 0
            indicator.buffer[i] = empty_digit(indicator)
        else
            indicator.buffer[i] = NUM_TRANSLATOR[digit_vector[i]]
        end
    end

    fill!(indicator.dp_buffer, 0b0)
    if dp_position >= 0 && 1 <= dp_position <= length(indicator.digits_pins)
        indicator.dp_buffer[dp_position] = 0b1
    end

    update(indicator)
end
=#
