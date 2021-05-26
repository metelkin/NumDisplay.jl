module NumDisplay

using PiGPIOC

export DisplayBCD
export write_digit, write_number, update, clean, stop
export NO_DIGIT

include("abstract-num-display.jl")
include("display-bcd.jl")

end # module
