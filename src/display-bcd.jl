const NO_DIGIT = 0b1111

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
    struct DisplayBCD <: AbstractNumDisplay
        sectors_pins::AbstractVector{Int}   # pin numbers starting from less significant
        input_pins::Tuple{Int,Int,Int,Int}  # pin numbers for binary code starting from less significant
        dp_pin::Union{Int, Nothing}         # pin changing dot state
        buffer::AbstractVector{UInt8}       # internal storage of digits values
        dp_buffer::AbstractVector{UInt8}
        usDelay::Int                        # duration of period when sector is on
    end
"""
struct DisplayBCD <: AbstractNumDisplay
    sectors_pins::AbstractVector{Int}
    input_pins::Tuple{Int,Int,Int,Int}
    dp_pin::Union{Int, Nothing}
    buffer::AbstractVector{UInt8}
    dp_buffer::AbstractVector{UInt8}
    usDelay::Int
end

"""
    function DisplayBCD(
        sectors_pins::AbstractVector{Int},
        input_pins::Tuple{Int,Int,Int,Int},
        dp_pin::Union{Int, Nothing} = nothing;
        fps::Int = 1000
    )

Creates device representing numerical display with several digits under control of the BCD chip.
The number of display digits equal to `sectors_pins` count.

## Arguments

- sectors_pins : Vector of GPIO pin numbers connected to anode. The HIGH state means the digit is on. LOW means off.
    The first pin in array should manage the less significant digit.

- input_pins : Tuple consisting of GPIO numbers representing the 4-bit code of a digit.
    The first pin in tuple is less significant number.

- dp_pin : Number of pin connected to dot LED (DP)

- fps : frame rate (frames per second). The digits in display are controlled by impulses of `sectors_pins`. 
    This argument sets the width of one impuls. 
    If `fps=1000` the width will be recalculated as `1/1000 = 1e-3` second or `1e3` microsecond.
    The default value is `1000` Hz.
"""
function DisplayBCD(
    sectors_pins::AbstractVector{Int},
    input_pins::Tuple{Int,Int,Int,Int},
    dp_pin::Union{Int, Nothing} = nothing;
    fps::Int = 1000 # Hz
)
    if PiGPIOC.gpioInitialise() < 0
        throw("pigpio initialisation failed.")
    else
        @info "pigpio initialised okay."
    end

    # set frequency
    usDelay = ceil(Int, 10^6 / fps) # conversion to us
    # TODO: display real frequency
    # TODO: check upper frequency
    # TODO: check lower frequency, gpioWaveGetMaxMicros()

    # init pins
    PiGPIOC.gpioSetMode.(sectors_pins, PiGPIOC.PI_OUTPUT)
    PiGPIOC.gpioWrite.(sectors_pins, 0)
    PiGPIOC.gpioSetMode.(input_pins, PiGPIOC.PI_OUTPUT)
    PiGPIOC.gpioWrite.(input_pins, 0)
    if dp_pin !== nothing
        PiGPIOC.gpioSetMode(dp_pin, PiGPIOC.PI_OUTPUT)
        PiGPIOC.gpioWrite(dp_pin, 0)
    end

    buffer = fill(NO_DIGIT, length(sectors_pins)) # set empty display
    dp_buffer = fill(0b0, length(sectors_pins)) # set all false

    DisplayBCD(sectors_pins, input_pins, dp_pin, buffer, dp_buffer, usDelay)
end

"""
    function write_digit(
        indicator::DisplayBCD,
        digit::Union{UInt8, Nothing},
        position::Int
    )

Writes the digit to the position. The result of the execution is changing one digit in a particular sector. 

## Arguments

- indicator : object representing display device

- digit : decimal value from 0 to 9 or `nothing`. The last means an empty sector.
        Values from 10 to 14 are also possible here but results to miningless symbols.
        Value 15 means an empty sector and it is the same as `nothing`.

- position : number of sector to write starting from 1 which mean less signifacant digit.
        The maximal value depends on available sectors, so it should be `<= length(indicator.digit_pins)`
 
"""
function write_digit(
    indicator::DisplayBCD,
    value::Union{UInt8, Nothing}, # digit from 0 to 9
    position::Int # starting from less signifacant
)
    @assert 0 <= value <= 15 "value must be in range [0...15], got $digit"
    @assert 1 <= position <= length(indicator.sectors_pins) "position must be in range [1...$(length(indicator.sectors_pins))], got , got $position"

    indicator.buffer[position] = value !== nothing ? value : NO_DIGIT

    update(indicator)
end

function write_dp(
    indicator::DisplayBCD,
    value::UInt8,
    position::Int # starting from less signifacant
)
    @assert 0 <= value <= 1 "value must be 0 or 1, got $digit"
    @assert 1 <= position <= length(indicator.sectors_pins) "position must be in range [1...$(length(indicator.sectors_pins))], got , got $position"

    indicator.dp_buffer[position] = value

    update(indicator)
end

"""
    function write_number(
        indicator::DisplayBCD,
        digit_vector::AbstractArray{D},
        dp_position::Union(Int,Nothing) = nothing
    ) where D <: Union{UInt8, Nothing}

Writes several digits to the positions. The result of the execution is updating the whole number.
If `digit_vector` is shorter than number of sectors the rest sectors will be empty.

## Arguments

- indicator : object representing display device

- digit_vector : vector of decimal values from 0 to 9 or `nothing`. The same meaning as `digit` in `write_digit()`.
    The first element of vector will be writte to the less significant sector, etc.

- dp_position : position of dot in display
## Example

```
# d is 4-digit (sector) display
write_number(d, [1,2])
# the result is __321

write_number(d, [1,2,3,4])
# the result is 4321

write_number(d, [1,2,3,4,5,6])
# the result is 4321
```
"""
function write_number(
    indicator::DisplayBCD,
    digit_vector::AbstractArray{D}, # digit from 0 to 9
    dp_position::Union{Int, Nothing} = nothing
) where D <: Union{UInt8, Nothing}
    # TODO: check digit_vector
    l = length(digit_vector)
    for i in 1:length(indicator.sectors_pins)
        indicator.buffer[i] = (i <= l && digit_vector[i] !== nothing) ? digit_vector[i] : NO_DIGIT
    end

    fill!(indicator.dp_buffer, 0b0)
    if dp_position !== nothing && 1 <= dp_position <= length(indicator.sectors_pins)
        indicator.dp_buffer[dp_position] = 0b1
    end

    update(indicator)
end

"""
    write_number(
        indicator::DisplayBCD,
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
    indicator::DisplayBCD,
    number::Int,
    dp_position::Union{Int, Nothing} = nothing
)
    indicator_len = length(indicator.sectors_pins)

    @assert 0 <= number < 10^indicator_len "number $number cannot be displayed on $indicator_len indicator"   

    digit_vector = UInt8.(digits(number))

    write_number(indicator, digit_vector, dp_position)
end

"""
    update(indicator::DisplayBCD)

Show the content of `indicator.buffer` to the display.
This function is used internaly by `write...` methods to update the display.

## Arguments

- indicator : object representing display device

"""
function update(indicator::DisplayBCD)
    digits_count = length(indicator.sectors_pins)

    # create new wave based on indicator.buffer
    # number of pulses is equal to digits_count
    pulse = PiGPIOC.gpioPulse_t[]
    for i in 1:digits_count
        gpioOn = 0
        gpioOff = 0
        for j in 1:digits_count
            if i == j
                gpioOn |= 1 << indicator.sectors_pins[j]
            else
                gpioOff |= 1 << indicator.sectors_pins[j]
            end
        end

        value = indicator.buffer[i]
        for j in 1:4
            if value % 2 == 1
                gpioOn |= 1 << indicator.input_pins[j]
            else
                gpioOff |= 1 << indicator.input_pins[j]
            end
            value >>= 1
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
    clean(indicator::DisplayBCD)

Display empty sectors.

## Arguments

- indicator : object representing display device

"""
function clean(indicator::DisplayBCD)
    fill!(indicator.buffer, NO_DIGIT)
    fill!(indicator.dp_buffer, 0b0)
    update(indicator)
end

"""
    stop(indicator::DisplayBCD)

Stop device and reset the the initial state.

## Arguments

- indicator : object representing display device

"""
function stop(indicator::DisplayBCD)
    # stop wave
    # current_wave = PiGPIOC.gpioWaveTxAt()
    # PiGPIOC.gpioWaveDelete(current_wave)
    PiGPIOC.gpioWaveTxStop()

    # clear buffer
    fill!(indicator.buffer, NO_DIGIT)
    fill!(indicator.dp_buffer, 0b0)

    # clear pins
    PiGPIOC.gpioWrite.(indicator.sectors_pins, 0)
    PiGPIOC.gpioWrite.(indicator.input_pins, 0)
    if indicator.dp_pin !== nothing
        PiGPIOC.gpioWrite(indicator.dp_pin, 0)
    end
end
