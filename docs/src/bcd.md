# BCD approach

BCD is a Binary-Coded Decimal chip which can be used to manage display with several digits.

The method requires 4 pins to display decimal and additionally one pin per sector.
For example 4 sector-display requires 4 + 4 = 8 GPIO pins. 

**Common anode chips**

- **246** : SN54246, SN74246
- **247** : SN54247, SN74247
- **LS247** : SN54LS247, SN74LS247(*)
- **LS248** : SN54LS248, SN74LS248

(*) tested

## Usage

```julia
using NumericDisplay
d = DisplayBCD(
    [       # pins to on/off sectors
        27, # less significant decimal digit
        22,
        10,
        9   # most significant decimal digit
    ],
    (      # pins connected to chip to transform bits to decimal number
        2, # A (less significant bit)
        3, # B
        4, # C
        17 # D (most significant bit)
    )
)

write_number(d, 666) # display _666
sleep(1)
stop(d)              # display nothing
```

## Circuit

![scheme-bcd](./scheme-bcd.png)

**Notes**

- Here I was using the NPN transistors to switch digits because I had them but MOSFETs is also possible here
- To use the dot symbol (which is also available on the indicator) it is required to add one additional pin.
