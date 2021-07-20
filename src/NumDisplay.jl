module NumDisplay

using PiGPIOC

# constructors
#, DisplayBCD
export DisplaySPI, DisplayDirect, DisplayBCD

# low level
export scan_rate, decode_mode, set_intensity, set_limit, shutdown_mode_on, shutdown_mode_off,
    test_mode_on, test_mode_off, write_digit,
    update

# high level
export write_number, write_symbols

include("decoding.jl")
include("extend.jl")
include("abstract-num-display.jl")
include("display-no-buffer.jl")
include("display-direct.jl")
include("display-bcd.jl")
include("display-spi.jl")

end # module
