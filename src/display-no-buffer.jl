abstract type DisplayNoBuffer <: AbstractNumDisplay end

scan_rate(d::DisplayNoBuffer) = ceil(Int, 10^6 / d.usDelay) # Hz

size(d::DisplayNoBuffer) = length(d.digits_pins)

# update wave based on buffer
function generate_wave(d::DisplayNoBuffer)
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
        decode_i = (decode_mode(d) >> (i - 1)) % 2

        # sectors
        buffer_i = d.buffer[i]
        if decode_i == 0
            value = buffer_i
        else
            value = NUM_TRANSLATOR[buffer_i % 0b00010000] # get 4 least significant bits
            dp_state = buffer_i >> 7
            value += dp_state << 7
        end

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
    function update(d::DisplayNoBuffer)

Generates a sequence of pulses based on buffer, decode_mode, intensity, limit, and runs pulses repeatedly.
The function is used internally after buffer and modes changes.
If a display is in shutdown mode, the function does nothing. 
"""
function update(d::DisplayNoBuffer)
    # do nothing in shutdown mode
    if PiGPIOC.gpioWaveTxBusy() == 1
        wave_id = d.test_mode ? generate_test_wave(d) : generate_wave(d)
        run_wave(wave_id)
    end
end

function shutdown_mode_off(d::DisplayNoBuffer)
    # do nothing in normal mode or test mode
    if PiGPIOC.gpioWaveTxBusy() == 0
        wave_id = d.test_mode ? generate_test_wave(d) : generate_wave(d)
        run_wave(wave_id)
    end
end

function shutdown_mode_on(d::DisplayNoBuffer)
    # stop current wave
    PiGPIOC.gpioWaveTxStop()
        
    # clear pins
    PiGPIOC.gpioWrite(d.digits_pins, 0)
    PiGPIOC.gpioWrite(d.sectors_pins, 0)
end

function test_mode_off(d::DisplayNoBuffer)
    # do nothing in normal mode
    if d.test_mode
        d.test_mode = false
        update(d)
    end
end

function test_mode_on(d::DisplayNoBuffer)
    # do nothing in test mode
    if !d.test_mode
        d.test_mode = true
        update(d)
    end
end

function set_limit(d::DisplayNoBuffer, limit::Int = size(d))
    @assert 1 <= limit <= size(d) "limit must be between 1 and $(size(d)), got $limit"
    d.limit = limit

    update(d)
    # set empty states
    pins_to_free = (d.limit+1):size(d)
    PiGPIOC.gpioWrite(d.digits_pins[pins_to_free], !d.inverted_digits ? 0 : 1)
end

function set_intensity(d::DisplayNoBuffer, intensity::Int = 16)
    @assert 1 <= intensity <= 16 "intensity must be between 1 and 16, got $intensity"
    d.intensity = intensity
    
    update(d)
end

"""
    function write_digit(
        indicator::DisplayBCD,
        digit::Union{UInt8, Nothing},
        position::Int
    )

Writes a digit to the position. The result of the execution is changing one digit in a particular digit. 

## Arguments

- `indicator` : object representing display device

- `digit` : decimal value from 0 to 9 or `nothing`. The last means an empty digit.
        Values from 10 to 14 are also possible here but results to miningless symbols.
        Value 15 means an empty digit and it is the same as `nothing`.

- `position` : number of digit to write starting from 1 which mean less significant digit.
        The maximal value depends on available digits, so it should be `<= length(indicator.digit_pins)`
 
"""
function write_digit(
    d::DisplayNoBuffer,
    value::UInt8,
    position::Int
)
    @assert 1 <= position <= 8 "position must be between 1 and 8, got $position"
    d.buffer[position] = value

    # update only in normal mode
    if !d.test_mode
        update(d)
    end
end

#= This can change all digits in Display
"""
    function write_number(
        indicator::DisplayBCD,
        digit_vector::AbstractArray{D},
        dp_position::Union(Int,Nothing) = nothing
    ) where D <: Union{UInt8, Nothing}

Writes several digits to the positions. The result of the execution is updating the whole number.
If `digit_vector` is shorter than number of digits the rest digits will be empty.

## Arguments

- `indicator` : object representing display device

- `digit_vector` : vector of decimal values from 0 to 9 or `nothing`. The same meaning as `digit` in `write_digit()`.
    The first element of vector will be write to the less significant digit, etc.

- `dp_position` : position of dot in display
## Example

```
# d is 4-digit display
write_number(d, [1,2])
# the result is __321

write_number(d, [1,2,3,4])
# the result is 4321

write_number(d, [1,2,3,4,5,6])
# the result is 4321
```
"""
function write_number(
    indicator::DisplayNoBuffer,
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
