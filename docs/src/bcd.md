# BCD approach

BCD is a Binary-Coded Decimal chip which can be used to manage display with several digits.

The chip transforms the binary code (4 bits: A, B, C, D) to the 7-segment (a,b,c,d,e,f,g) LED states representing decimal number. If you use the indicator with common anode you need to switch the digits by additional signal: one pin for one digit. 

The method requires 4 pins to display decimal and additionally one pin per digit.
For example 4-digits-display requires 4 + 4 = 8 GPIO pins. 
8-digits-display requires 4 + 8 = 12 GPIO pins.

If you use dot on display you need the additional pin.
For example 4-digits-display requires 4 + 1 + 4 = 9 GPIO pins. 

**Common anode chips examples**

- **246** : SN54246, SN74246
- **247** : SN54247, SN74247
- **LS247** : SN54LS247, SN74LS247(*)
- **LS248** : SN54LS248, SN74LS248

(*) was tested

## Usage

**Without dot**

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

**With dot**

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
    ),
    11     # pin to control dot
)

write_number(d, 666) # display _666
sleep(1)
write_number(d, 666, 2) # display _66.6
sleep(1)
stop(d)              # display nothing
```

## Circuit

**Without dot**

![bcd-scheme](./bcd-scheme.png)

[![Watch the video](https://img.youtube.com/vi/gWjStU8-2Ug/hqdefault.jpg)](https://youtu.be/gWjStU8-2Ug)

**Notes**

- Here I was using the NPN transistors to switch digits because I had them but MOSFETs was also possible there.
- To use the dot symbol (which is also available on the indicator) it is required to add one additional pin.
