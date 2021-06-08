abstract type AbstractNumDisplay end

"""
    write_number(
        indicator::AbstractNumDisplay,
        number::Int,
        dp_position::Union{Int, Nothing} = nothing
    )

Writes the decimal value to the display.

## Arguments

- `indicator` : object representing display device

- `number` : decimal number. The maximal possible value depends on number of digits and will be checked.

- `dp_position` : position of digit starting from less significant digit or nothing.

## Example

```
# d is 4-digit display
write_number(d, 123)
# the result is _123

write_number(d, 1234)
# the result is 1234

write_number(d, 12345)
# throws an error
```
"""
function write_number(
    d::AbstractNumDisplay,
    number::Int,
    dp_position::Union{Int, Nothing} = nothing
)
    @assert 0 <= number < 10^8 "number $number cannot be displayed on 8-digits indicator"   

    write_number(d, digits(number), dp_position)
end

"""
Writes several digits
Runs display in decode mode and display several digits
element in numer_vector must be Integers
"""
function write_number(
    d::AbstractNumDisplay,
    number_vector::AbstractArray{D},
    dp_position::Union{Int, Nothing} = nothing
) where D <: Union{Int, Nothing}
    l = length(number_vector)
    set_limit(d, l)
    decode_mode(d)

    for i in 1:l
        num_i = number_vector[i] !== nothing ? number_vector[i] : 15
        is_dot = dp_position == i
        @assert 0 <= num_i <= 15 "number in vector must be between 0 and 15, got $num_i"

        digit_i = is_dot << 7 | num_i # dot coded by most significant bit
        write_digit(d, UInt8(digit_i), i)
    end
end

"""
works in segment-wise mode
set active segments DP A B C D E F G
"""
function write_symbols(
    d::AbstractNumDisplay,
    byte_vector::AbstractArray{UInt8},
)
    l = length(byte_vector)
    set_limit(d, l)
    decode_mode(d, 0x0)

    for i in 1:l
        write_digit(d, byte_vector[i], i)
    end
end

function write_symbols(
    d::AbstractNumDisplay,
    symbol_vector::AbstractArray{Char},
)
    # CHAR_TRANSLATOR
    byte_vector = [get(CHAR_TRANSLATOR, char, 0b00000000) for char in symbol_vector]
    write_symbols(d, byte_vector)
end

function write_symbols(
    d::AbstractNumDisplay,
    s::String
)
    symbol_vector = collect(s)
    write_symbols(d, reverse(symbol_vector))
end

"""
    update(indicator::AbstractNumDisplay)

Show the content of `indicator.buffer` to the display.
This function is used internaly by `write...` methods to update the display.

## Arguments

- `indicator` : object representing display device

"""
function update(indicator::AbstractNumDisplay)
    digits_count = length(indicator.digits_pins)

    # create new wave based on indicator.buffer
    # number of pulses is equal to digits_count
    pulse = PiGPIOC.gpioPulse_t[]
    for i in 1:digits_count
        gpioOn = 0
        gpioOff = 0
        for j in 1:digits_count
            if xor(i == j, indicator.inverted_digits)
                gpioOn |= 1 << indicator.digits_pins[j]
            else
                gpioOff |= 1 << indicator.digits_pins[j]
            end
        end

        # digits
        value = indicator.buffer[i]
        for j in 1:length(indicator.input_pins)
            if xor(value % 2 == 1, indicator.inverted_input)
                gpioOn |= 1 << indicator.input_pins[j]
            else
                gpioOff |= 1 << indicator.input_pins[j]
            end
            value >>= 1
        end

        # dots
        if indicator.dp_pin !== nothing
            dot = indicator.dp_buffer[i]
            if xor(dot > 0, indicator.inverted_input)
                gpioOn |= 1 << indicator.dp_pin
            else
                gpioOff |= 1 << indicator.dp_pin
            end
        end

        push!(pulse, PiGPIOC.gpioPulse_t(gpioOn, gpioOff, indicator.usDelay)) # on, off, usDelay
    end

    PiGPIOC.gpioWaveAddGeneric(digits_count, pulse)
    wave_id = PiGPIOC.gpioWaveCreate()
    if wave_id < 0
        # return Upon success a wave id greater than or equal to 0 is returned, 
        # otherwise PI_EMPTY_WAVEFORM, PI_TOO_MANY_CBS, PI_TOO_MANY_OOL,
        # or PI_NO_WAVEFORM_ID
        throw("Error in 'PiGPIOC.gpioWaveCreate()' with code: $(wave_id)")
    end

    # get old
    old_wave_id = PiGPIOC.gpioWaveTxAt()

    # run new wave when possible
    ret_code = PiGPIOC.gpioWaveTxSend(wave_id, PiGPIOC.PI_WAVE_MODE_REPEAT_SYNC)
    if ret_code < 0
        # return the number of DMA control blocks in the waveform if OK, 
        # otherwise PI_BAD_WAVE_ID, or PI_BAD_WAVE_MODE
        throw("Error in 'PiGPIOC.gpioWaveCreate()' with code: $(ret_code)")
    end

    # safe delete old wave
    no_old_wave = old_wave_id == PiGPIOC.PI_NO_TX_WAVE || # 9999
        old_wave_id == PiGPIOC.PI_WAVE_NOT_FOUND # 9998
    if !no_old_wave
        while PiGPIOC.gpioWaveTxAt() != wave_id
            # wait for starting new wave
        end
        PiGPIOC.gpioWaveDelete(old_wave_id)
    end

    return nothing
end

"""
    clean(indicator::AbstractNumDisplay)

Display empty digits.

## Arguments

- `indicator` : object representing display device

"""
function clean(indicator::AbstractNumDisplay)
    fill!(indicator.buffer, empty_digit(indicator))
    fill!(indicator.dp_buffer, 0b0)
    update(indicator)
end

"""
    stop(indicator::AbstractNumDisplay)

Stop device and reset the the initial state.

## Arguments

- `indicator` : object representing display device

"""
function stop(indicator::AbstractNumDisplay)
    # stop wave
    # current_wave = PiGPIOC.gpioWaveTxAt()
    # PiGPIOC.gpioWaveDelete(current_wave)
    PiGPIOC.gpioWaveTxStop()

    # clear buffer
    fill!(indicator.buffer, empty_digit(indicator))
    fill!(indicator.dp_buffer, 0b0)

    # clear pins
    PiGPIOC.gpioWrite.(indicator.digits_pins, 0)
    PiGPIOC.gpioWrite.(indicator.input_pins, 0)
    if indicator.dp_pin !== nothing
        PiGPIOC.gpioWrite(indicator.dp_pin, 0)
    end
end
