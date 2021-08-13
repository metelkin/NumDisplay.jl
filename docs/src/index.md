# NumDisplay

Raspberry Pi package for controlling the 7-segment numeric displays written in Julia.

The package supports several approaches:

- Direct method does not use any chips transforming input but it requires more GPIO pins. See [DisplayDirect](https://metelkin.github.io/NumDisplay.jl/dev/direct/).
- BCD is a Binary-Coded Decimal chip which can be used to manage display with several digits. See [DisplayBCD](https://metelkin.github.io/NumDisplay.jl/dev/bcd/).
- SPI uses MAX7219/MAX7221 chip to control up to 8 digits 7-segment displays. See [DisplaySPI](https://metelkin.github.io/NumDisplay.jl/dev/spi/).

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

## Notes

- To run the code you need the full access to GPIO. Run it under sudo privileges.

Example running the code from "test/run.jl".
```julia
sudo julia --project=. test/run.jl
```
