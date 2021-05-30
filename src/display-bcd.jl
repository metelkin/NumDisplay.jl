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
        dp_buffer::AbstractVector{UInt8}    # internal storage for dot states
        usDelay::Int                        # duration of period when sector is on
        inverted_sectors::Bool              # if sector pins states must be inverted, i.e. 1 means LOW pin state
        inverted_input::Bool                # if input pins and dp pin states must be inverted, i.e. 1 means LOW pin state
    end
"""
struct DisplayBCD <: AbstractNumDisplay
    sectors_pins::AbstractVector{Int}
    input_pins::Tuple{Int,Int,Int,Int}
    dp_pin::Union{Int, Nothing}
    buffer::AbstractVector{UInt8}
    dp_buffer::AbstractVector{UInt8}
    usDelay::Int
    inverted_sectors::Bool
    inverted_input::Bool
end

empty_sector(::DisplayBCD) = 0b1111 # NO_DIGIT

"""
    function DisplayBCD(
        sectors_pins::AbstractVector{Int},
        input_pins::Tuple{Int,Int,Int,Int},
        dp_pin::Union{Int, Nothing} = nothing;
        fps::Int = 1000,
        inverted_sectors::Bool = false,
        inverted_input::Bool = false
    )

Creates device representing numerical display with several digits under control of the BCD chip.
The number of display digits equal to `sectors_pins` count.

## Arguments

- `sectors_pins` : Vector of GPIO pin numbers connected to anode. The HIGH state means the digit is on. LOW means off.
    The first pin in array should manage the less significant digit.

- `input_pins` : Tuple consisting of GPIO numbers representing the 4-bit code of a digit.
    The first pin in tuple is less significant number.

- `dp_pin` : Number of pin connected to dot LED (DP)

- `fps` : frame rate (frames per second). The digits in display are controlled by impulses of `sectors_pins`. 
    This argument sets the width of one impuls. 
    If `fps=1000` the width will be recalculated as `1/1000 = 1e-3` second or `1e3` microsecond.
    The default value is `1000` Hz.

- `inverted_sectors` : set `true` if displayed sector corresponds to LOW pin state. It depends on the curcuit used.

- `inverted_input` : set `true` if input and dot state should be inverted before sending to the physical device. It depends on the curcuit used.
"""
function DisplayBCD(
    sectors_pins::AbstractVector{Int},
    input_pins::Tuple{Int,Int,Int,Int},
    dp_pin::Union{Int, Nothing} = nothing;
    fps::Int = 1000, # Hz
    inverted_sectors::Bool = false,
    inverted_input::Bool = false
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

    buffer = fill(0b1111, length(sectors_pins)) # set empty display
    dp_buffer = fill(0b0, length(sectors_pins)) # set all false

    DisplayBCD(
        sectors_pins,
        input_pins,
        dp_pin,
        buffer,
        dp_buffer,
        usDelay,
        inverted_sectors,
        inverted_input
    )
end

"""
    function write_digit(
        indicator::DisplayBCD,
        digit::Union{UInt8, Nothing},
        position::Int
    )

Writes a digit to the position. The result of the execution is changing one digit in a particular sector. 

## Arguments

- `indicator` : object representing display device

- `digit` : decimal value from 0 to 9 or `nothing`. The last means an empty sector.
        Values from 10 to 14 are also possible here but results to miningless symbols.
        Value 15 means an empty sector and it is the same as `nothing`.

- `position` : number of sector to write starting from 1 which mean less signifacant digit.
        The maximal value depends on available sectors, so it should be `<= length(indicator.digit_pins)`
 
"""
function write_digit(
    indicator::DisplayBCD,
    value::Union{UInt8, Nothing}, # digit from 0 to 9
    position::Int # starting from less signifacant
)
    @assert 0 <= value <= 15 "value must be in range [0...15], got $value"
    @assert 1 <= position <= length(indicator.sectors_pins) "position must be in range [1...$(length(indicator.sectors_pins))], got , got $position"

    if value === nothing
        indicator.buffer[position] = empty_sector(indicator)
    else
        indicator.buffer[position] = value 
    end

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

- `indicator` : object representing display device

- `digit_vector` : vector of decimal values from 0 to 9 or `nothing`. The same meaning as `digit` in `write_digit()`.
    The first element of vector will be writte to the less significant sector, etc.

- `dp_position` : position of dot in display
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
        indicator.buffer[i] = (i <= l && digit_vector[i] !== nothing) ? digit_vector[i] : empty_sector(indicator)
    end

    fill!(indicator.dp_buffer, 0b0)
    if dp_position !== nothing && 1 <= dp_position <= length(indicator.sectors_pins)
        indicator.dp_buffer[dp_position] = 0b1
    end

    update(indicator)
end
