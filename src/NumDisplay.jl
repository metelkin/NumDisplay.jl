module NumDisplay

using PiGPIOC

# constructors
# DisplayDirect, DisplayBCD
export DisplaySPI

# low level
export scan_rate, decode_mode, set_intensity, set_limit, shutdown_mode_on, shutdown_mode_off,
    test_mode_on, test_mode_off, write_digit

# update, clean, stop, empty_sector

# high level
export write_number, write_symbols

include("decoding.jl")
include("abstract-num-display.jl")
#include("display-direct.jl")
#include("display-bcd.jl")
include("display-spi.jl")

end # module