
# 0b0000000

mutable struct DisplayDirect <: AbstractNumDisplay
    digits_pins::AbstractVector{Int}
    sectors_pins::Tuple{Union{Int,Nothing},Int,Int,Int,Int,Int,Int} # DP a b c d e f g
    buffer::AbstractVector{UInt8}
    usDelay::Int
    inverted_digits::Bool
    inverted_sectors::Bool
    decode_mode::UInt8
    intensity::Int
    limit::Int
end

scan_rate(d::DisplayDirect) = ceil(Int, 10^6 / d.usDelay) # Hz

function DisplayDirect(
    digits_pins::AbstractVector{Int},
    sectors_pins::Tuple{Union{Int,Nothing},Int,Int,Int,Int,Int,Int,Int};
    scan_rate::Real = 800, # Hz
    common_cathode::Bool = false
)
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
    usDelay = ceil(Int, 10^6 / scan_rate) # conversion to us
    
    # init pins
    PiGPIOC.gpioSetMode.(digits_pins, PiGPIOC.PI_OUTPUT)
    PiGPIOC.gpioWrite.(digits_pins, 0)
    PiGPIOC.gpioSetMode.(sectors_pins, PiGPIOC.PI_OUTPUT)
    PiGPIOC.gpioWrite.(sectors_pins, 0)

    buffer = fill(0b0000000, length(digits_pins))
    decode_mode = 0b00000000

    d = DisplayDirect(
        digits_pins,
        sectors_pins,
        buffer,
        usDelay,
        inverted_digits,
        inverted_sectors,
        decode_mode,
        5, # default intensity
        1 # default limit
    )

    return d
end

# update wave based on buffer
function get_wave(d::DisplayDirect)
    # create new wave based on d.buffer
    # number of pulses is equal to digits_count
    pulse = PiGPIOC.gpioPulse_t[]
    for i in 1:d.limit
        gpioOn = 0
        gpioOff = 0

        # digits
        for j in 1:d.limit
            if xor(i == j, d.inverted_digits)
                gpioOn |= 1 << d.digits_pins[j]
            else
                gpioOff |= 1 << d.digits_pins[j]
            end
        end

        # sectors
        value = d.buffer[i]
        for j in 1:8
            if xor(value % 2 == 1, d.inverted_sectors)
                gpioOn |= 1 << d.sectors_pins[j]
            else
                gpioOff |= 1 << d.sectors_pins[j]
            end
            value >>= 1
        end

        push!(pulse, PiGPIOC.gpioPulse_t(gpioOn, gpioOff, d.usDelay)) # on, off, usDelay
    end

    PiGPIOC.gpioWaveAddGeneric(d.limit, pulse)
    wave_id = PiGPIOC.gpioWaveCreate()
    if wave_id < 0
        # return Upon success a wave id greater than or equal to 0 is returned, 
        # otherwise PI_EMPTY_WAVEFORM, PI_TOO_MANY_CBS, PI_TOO_MANY_OOL,
        # or PI_NO_WAVEFORM_ID
        throw("Error in 'PiGPIOC.gpioWaveCreate()' with code: $(wave_id)")
    end

    return wave_id
end

# stop previous (if active) and run
function run_wave(d::DisplayDirect, wave_id::Int)
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

function shutdown_mode_off(d::DisplayDirect)
    # do nothing in normal mode
    if PiGPIOC.gpioWaveTxBusy() == 0
        wave_id = get_wave(d)
        run_wave(d, wave_id)
    end
end

function shutdown_mode_on(d::DisplayDirect)
    # do nothing in shutdown mode
    if PiGPIOC.gpioWaveTxBusy() == 1
        # stop current wave
        PiGPIOC.gpioWaveTxStop()
    
        # clear pins
        PiGPIOC.gpioWrite.(indicator.digits_pins, 0)
        PiGPIOC.gpioWrite.(indicator.sectors_pins, 0)
    end
end

function set_limit(d::DisplayDirect, limit::Int = 8)
    @assert 1 <= limit <= 8 "limit must be between 1 and 8, got $limit"
    d.limit = limit

    if PiGPIOC.gpioWaveTxBusy() == 1
        wave_id = get_wave(d)
        run_wave(d, wave_id)
    end
end

function write_digit(
    d::DisplayDirect,
    value::UInt8,
    position::Int # starting from less significant
)
    @assert 1 <= position <= 8 "position must be between 1 and 8, got $position"

    d.buffer[position] = value

    if PiGPIOC.gpioWaveTxBusy() == 1
        wave_id = get_wave(d)
        run_wave(d, wave_id)
    end
end

#=
function write_number(
    indicator::DisplayDirect,
    digit_vector::AbstractArray{D}, # digit from 0 to 9
    dp_position::Union{Int, Nothing} = nothing
) where D <: Union{UInt8, Nothing}
    # TODO: check digit_vector
    l = length(digit_vector)
    for i in 1:length(indicator.digits_pins)
        if i > l || digit_vector[i] === nothing
            indicator.buffer[i] = empty_digit(indicator)
        else
            indicator.buffer[i] = NUM_TRANSLATOR[digit_vector[i]]
        end
    end

    fill!(indicator.dp_buffer, 0b0)
    if dp_position !== nothing && 1 <= dp_position <= length(indicator.digits_pins)
        indicator.dp_buffer[dp_position] = 0b1
    end

    update(indicator)
end
=#
