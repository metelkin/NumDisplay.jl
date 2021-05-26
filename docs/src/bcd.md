# BCD approach

BCD is a Binary-Coded Decimal chip which can be used to manage display with several digits.

**Common anode chips**

- **246** : SN54246, SN74246
- **247** : SN54247, SN74247
- **LS247** : SN54LS247, SN74LS247*
- **LS248** : SN54LS248, SN74LS248

\* tested

### usage

```julia
using NumericDisplay
d = DisplayBCD(
    [       # pins to on/off digits
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

## Circuits

![scheme-bcd](./scheme-bcd.png)

**Notes**

- Here I was using the NPN transistors to switch digits because I had them but MOSFETs is also possible here
