# push!(LOAD_PATH,"Y:/_raspberry/") # for local run
# push!(LOAD_PATH,"../")

using Documenter, NumDisplay

makedocs(
    sitename = "NumDisplay Documentation",
    modules = [NumDisplay],
    pages = [
        "Home" => "index.md",
        "Methods" => [
            "Direct" => "direct.md",
            "BCD" => "bcd.md",
            "SPI" => "spi.md",
        ],
        "API refs" => "api.md",
    ],
)

deploydocs(
    repo = "github.com/metelkin/NumDisplay.jl.git",
    target = "build",
)
