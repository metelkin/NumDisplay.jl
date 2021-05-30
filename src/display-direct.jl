# g f e d c b a
# 0b0000000
const TRANSLATOR = Dict(
    UInt8(0) => 0b0111111,
    UInt8(1) => 0b0000110,
    UInt8(2) => 0b1011011,
    UInt8(3) => 0b1001111,
    UInt8(4) => 0b1100110,
    UInt8(5) => 0b1101101,
    UInt8(6) => 0b1111101,
    UInt8(7) => 0b0000111,
    UInt8(8) => 0b1111111,
    UInt8(9) => 0b1101111,

    UInt8(10) => 0b1011000,
    UInt8(11) => 0b1001100,
    UInt8(12) => 0b1100010,
    UInt8(13) => 0b1101001,
    UInt8(14) => 0b1111000,
    UInt8(15) => 0b0000000
)

struct DisplayDirect <: AbstractNumDisplay
    sectors_pins::AbstractVector{Int}
    input_pins::Tuple{Int,Int,Int,Int,Int,Int,Int}
    dp_pin::Union{Int, Nothing}
    buffer::AbstractVector{UInt8}
    dp_buffer::AbstractVector{UInt8}
    usDelay::Int
    inverted_sectors::Bool
    inverted_input::Bool
end

empty_sector(::DisplayDirect) = 0b0000000

function DisplayDirect(
    sectors_pins::AbstractVector{Int},
    input_pins::Tuple{Int,Int,Int,Int,Int,Int,Int},
    dp_pin::Union{Int, Nothing} = nothing;
    fps::Int = 1000, # Hz
    inverted_sectors::Bool = false,
    inverted_input::Bool = true
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

    buffer = fill(0b0000000, length(sectors_pins))
    dp_buffer = fill(0b0, length(sectors_pins))

    DisplayDirect(
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

function write_digit(
    indicator::DisplayDirect,
    value::Union{UInt8, Nothing}, # binary digit from 0 to 9
    position::Int # starting from less signifacant
)
    @assert 0 <= value <= 15 "value must be in range [0...15], got $value"
    @assert 1 <= position <= length(indicator.sectors_pins) "position must be in range [1...$(length(indicator.sectors_pins))], got , got $position"

    if value === nothing
        indicator.buffer[position] = empty_sector(indicator)
    else
        indicator.buffer[position] = TRANSLATOR[value]
    end

    update(indicator)
end

function write_number(
    indicator::DisplayDirect,
    digit_vector::AbstractArray{D}, # digit from 0 to 9
    dp_position::Union{Int, Nothing} = nothing
) where D <: Union{UInt8, Nothing}
    # TODO: check digit_vector
    l = length(digit_vector)
    for i in 1:length(indicator.sectors_pins)
        if i > l || digit_vector[i] === nothing
            indicator.buffer[i] = empty_sector(indicator)
        else
            indicator.buffer[i] = TRANSLATOR[digit_vector[i]]
        end
    end

    fill!(indicator.dp_buffer, 0b0)
    if dp_position !== nothing && 1 <= dp_position <= length(indicator.sectors_pins)
        indicator.dp_buffer[dp_position] = 0b1
    end

    update(indicator)
end