using NumDisplay

println("Starting...")

d = DisplaySPI()
shutdown_mode_off(d)

include("common-high-level-8.jl")

include("common-low-level-8.jl")

println("Stop.")
