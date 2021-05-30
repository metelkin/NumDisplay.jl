abstract type AbstractNumDisplay end

"""
    function write_dp(
        indicator::AbstractNumDisplay,
        dp_value::UInt8,
        dp_position::Int
    )

Writes a dot symbol to the position. The result of the execution is changing one dot in a particular sector. 

## Arguments

- indicator : object representing display device

- dp_value : value 0 or 1 to get dot OFF or ON.

- position : number of sector to write starting from 1 which mean less signifacant digit.
        The maximal value depends on available sectors, so it should be `<= length(indicator.digit_pins)`
 
"""
function write_dp(
    indicator::AbstractNumDisplay,
    dp_value::UInt8,
    dp_position::Int # starting from less signifacant
)
    @assert 0 <= dp_value <= 1 "dp_value must be 0 or 1, got $dp_value"
    @assert 1 <= dp_position <= length(indicator.sectors_pins) "dp_position must be in range [1...$(length(indicator.sectors_pins))], got , got $dp_position"

    indicator.dp_buffer[dp_position] = dp_value

    update(indicator)
end


"""
    write_number(
        indicator::AbstractNumDisplay,
        number::Int,
        dp_position::Union{Int, Nothing} = nothing
    )

Writes the decimal value to the display.

## Arguments

- indicator : object representing display device

- number : decimal number. The maximal possible value depends on number of sectors and will be checked.

## Example

```
# d is 4-digit (sector) display
write_number(d, 123)
# the result is _123

write_number(d, 1234)
# the result is 1234

write_number(d, 12345)
# throws an error
```
"""
function write_number(
    indicator::AbstractNumDisplay,
    number::Int,
    dp_position::Union{Int, Nothing} = nothing
)
    indicator_len = length(indicator.sectors_pins)

    @assert 0 <= number < 10^indicator_len "number $number cannot be displayed on $indicator_len indicator"   

    digit_vector = UInt8.(digits(number))

    write_number(indicator, digit_vector, dp_position)
end

"""
    update(indicator::AbstractNumDisplay)

Show the content of `indicator.buffer` to the display.
This function is used internaly by `write...` methods to update the display.

## Arguments

- indicator : object representing display device

"""
function update(indicator::AbstractNumDisplay)
    digits_count = length(indicator.sectors_pins)

    # create new wave based on indicator.buffer
    # number of pulses is equal to digits_count
    pulse = PiGPIOC.gpioPulse_t[]
    for i in 1:digits_count
        gpioOn = 0
        gpioOff = 0
        for j in 1:digits_count
            if xor(i == j, indicator.inverted_sectors)
                gpioOn |= 1 << indicator.sectors_pins[j]
            else
                gpioOff |= 1 << indicator.sectors_pins[j]
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

Display empty sectors.

## Arguments

- indicator : object representing display device

"""
function clean(indicator::AbstractNumDisplay)
    fill!(indicator.buffer, empty_sector(indicator))
    fill!(indicator.dp_buffer, 0b0)
    update(indicator)
end

"""
    stop(indicator::AbstractNumDisplay)

Stop device and reset the the initial state.

## Arguments

- indicator : object representing display device

"""
function stop(indicator::AbstractNumDisplay)
    # stop wave
    # current_wave = PiGPIOC.gpioWaveTxAt()
    # PiGPIOC.gpioWaveDelete(current_wave)
    PiGPIOC.gpioWaveTxStop()

    # clear buffer
    fill!(indicator.buffer, empty_sector(indicator))
    fill!(indicator.dp_buffer, 0b0)

    # clear pins
    PiGPIOC.gpioWrite.(indicator.sectors_pins, 0)
    PiGPIOC.gpioWrite.(indicator.input_pins, 0)
    if indicator.dp_pin !== nothing
        PiGPIOC.gpioWrite(indicator.dp_pin, 0)
    end
end
