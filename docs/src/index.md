# NumericDisplay

Raspberry Pi package for controlling the 7-segment numeric displays written in Julia.

## Installation

Julia must be installed on Raspberry Pi. 
I have tested on v1.1.0 which can be installed with:
```sh
sudo apt update
sudo apt install julia
```

The package can be installed from Julia environment with:

```julia
] add https://github.com/metelkin/NumDisplay.jl.git
```

## Approaches

- [using Binary-Coded Decimal (BCD) chip](bcd)
