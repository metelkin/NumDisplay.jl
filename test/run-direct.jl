using NumDisplay

println("Starting...")

d = DisplayDirect([27, 22, 10, 9], (14, 15, 18, 23, 24, 25, 8, 7))
shutdown_mode_off(d)

include("common-high-level-4.jl")

include("common-low-level-4.jl")

println("Stop.")
