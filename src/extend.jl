function PiGPIOC.gpioWrite(vector::AbstractVector{Int}, data::Int)
    for x in vector
        x >= 0 && PiGPIOC.gpioWrite(x, data)
    end
end

function PiGPIOC.gpioWrite(vector::NTuple{8,Int}, data::Int)
    for x in vector
        x >= 0 && PiGPIOC.gpioWrite(x, data)
    end
end

function PiGPIOC.gpioWrite(vector::NTuple{5,Int}, data::Int)
    for x in vector
        x >= 0 && PiGPIOC.gpioWrite(x, data)
    end
end

function PiGPIOC.gpioSetMode(vector::AbstractVector{Int}, data::Int)
    for x in vector
        x >= 0 && PiGPIOC.gpioSetMode(x, data)
    end
end

function PiGPIOC.gpioSetMode(vector::NTuple{8,Int}, data::Int)
    for x in vector
        x >= 0 && PiGPIOC.gpioSetMode(x, data)
    end
end

function PiGPIOC.gpioSetMode(vector::NTuple{5,Int}, data::Int)
    for x in vector
        x >= 0 && PiGPIOC.gpioSetMode(x, data)
    end
end

# stop previous (if active) and run
function run_wave(wave_id::Int)
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