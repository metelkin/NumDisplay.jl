# Direct approach

This method does not require any chip. Each segment in digit is managed by its own GPIO pin.
It can serve the common-anode and common-cathod display.

The method requires 7 pins to display decimal and additionally one pin per digit.
For example 4-digit-display requires 8 + 4 = 12 GPIO pins. 
8-digit-display requires 8 + 8 = 15 GPIO pins.

## Usage

**Without dot**

```julia
using NumericDisplay
d = DisplayDirect(
    [       # pins to on/off digits
        27, # less significant decimal digit
        22,
        10,
        9   # most significant decimal digit
    ],
    (      # pins connected to segments
        7, # g segment
        8, # f
        25, # e
        24, # d
        23, # c
        18, # b
        15, # a
        -1  # DP not used
    );
    inverted_sectors = true
)
shutdown_mode_off(d)
write_number(d, 666) # display _666

sleep(1)
shutdown_mode_on(d)              # display nothing
```

**With dot**

```julia
using NumericDisplay
d = DisplayDirect # pins to on/off digits
        27, # less significant decimal digit
        22,
        10,
        9   # most significant decimal digit
    ],
    (       # pins connected to segments
        7,  # g segment
        8,  # f
        25, # e
        24, # d
        23, # c
        18, # b
        15, # a
        14  # DP pin
    );   
    inverted_sectors = true
)

shutdown_mode_off(d)

write_number(d, 666) # display _666
sleep(1)
write_number(d, 666, 2) # display _66.6
sleep(1)
shutdown_mode_on(d)              # display nothing
```

## Circuit

**Common anode and cathode scheme**

![direct-scheme-anode](./direct-scheme-anode.png)

**Notes**

- The scheme uses power from 3.3V signal pins. To use the external power you need to use NPN or MOSFET transistors.
- If you use common anode, use `DisplayDirect(...; inverted_sectors=true, inverted_sectors=false)` in constructor.
- If you use common cathode, use `DisplayDirect(...; inverted_sectors=false, inverted_sectors=true)` in constructor.
