using NumDisplay

println("Starting...")

d = DisplaySPI()
shutdown_mode_off(d)

include("common-high-level.jl")

include("common-low-level.jl")

println("Stop.")
