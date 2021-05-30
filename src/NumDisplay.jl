module NumDisplay

using PiGPIOC

export DisplayDirect, DisplayBCD
export write_digit, write_dp, write_number, update, clean, stop, empty_sector

include("abstract-num-display.jl")
include("display-direct.jl")
include("display-bcd.jl")

end # module
