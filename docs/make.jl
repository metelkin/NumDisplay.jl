# push!(LOAD_PATH,"Y:/_raspberry/") # for local run
# push!(LOAD_PATH,"../")

using Documenter, NumDisplay

makedocs(
    sitename = "NumDisplay Documentation",
    modules = [NumDisplay],
    pages = [
        "Home" => "index.md",
        "BCD" => "bcd.md",
        "API" => "api.md",
    ],
)

deploydocs(
    repo = "github.com/metelkin/NumDisplay.jl.git",
    target = "build",
)
