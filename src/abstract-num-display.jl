abstract type AbstractNumDisplay end

### low level methods

"""
    scan_rate(d::AbstractNumDisplay)
Getter to display actual refresh rate.

## Return

- `Int` value in Hz 
"""
function scan_rate(d::AbstractNumDisplay)
    throw("Method is not applicable for $(typeof(d)) type")
end

"""
    size(d::AbstractNumDisplay)
Getter to show the maximal number of digits available for the display.
This is equal to the number of `digits_pins`.
"""
function size(d::AbstractNumDisplay) 
    throw("Method is not applicable for $(typeof(d)) type")
end

"""
    shutdown_mode_off(d::AbstractNumDisplay)

Sets the normal mode, i.e. display digits.
It should be run after initialization of device.
"""
function shutdown_mode_off(d::AbstractNumDisplay)
    throw("Method is not applicable for $(typeof(d)) type")
end

"""
    shutdown_mode_on(d::AbstractNumDisplay)

In shutdown mode you can update digits values and set different settings but nothing will be shown.
Shutdown can be used to save power or as an alarm to flash the display by
successively entering and leaving shutdown mode.
"""
function shutdown_mode_on(d::AbstractNumDisplay)
    throw("Method is not applicable for $(typeof(d)) type")
end

"""
    function test_mode_off(d::AbstractNumDisplay)

Sets the normal mode, i.e. display digits.
"""
function test_mode_off(d::AbstractNumDisplay)
    throw("Method is not applicable for $(typeof(d)) type")
end

"""
    function test_mode_on(d::AbstractNumDisplay)

Display-test mode turns all LEDs on.
Test mode overrides shutdown mode. Display remain in display-test mode
until the display is reconfigured for normal operation.
"""
function test_mode_on(d::AbstractNumDisplay)
    throw("Method is not applicable for $(typeof(d)) type")
end

"""
    function set_limit(d::AbstractNumDisplay, limit::Int = size(d))

The function sets how many digits are displayed.
Since the number of scanned digits affects
the display brightness, the scan-limit register should
not be used to blank portions of the display.

The default value equal to the maximal value.

## Arguments

- `d` : device instance
- `limit` : number of active digits, from 1 to size(d)
    1 means only digit 1 is shown. 4 meand 8 digits will be shown.
"""
function set_limit(d::AbstractNumDisplay, limit::Int = size(d))
    throw("Method is not applicable for $(typeof(d)) type")
end

"""
    function decode_mode(d::AbstractNumDisplay, decode::UInt8 = 0b1111_1111)

The decode-mode register sets BCD code (0-9, E, H,
L, P, and -) or no-decode operation for each digit. 

When the code B decode mode is used, the decoder
looks only at the lower nibble of the data in the digit
registers (D4–D1), disregarding bits D5–D7.
D8 sets the decimal point (DP).

When no-decode is selected, data bits D8–D1
correspond to the segment lines

all digits in decode mode => 0xff = 0b1111_1111
all digits in none-decode mode => 0x00 = 0b0000_0000
first decode other none mode => 0x01 = 0b0000_0001

## Arguments

- `d` : device instance
- `decode` : Each bit in the register corresponds to one digit. A logic high
    selects code decoding while logic low bypasses the decoder.
"""
function decode_mode(d::AbstractNumDisplay, decode::UInt8 = 0b1111_1111)
    throw("Method is not applicable for $(typeof(d)) type")
end

"""
    function set_intensity(d::AbstractNumDisplay, intensity::Int = 16)

Digital control of display brightness is provided by an
internal pulse-width modulator.

## Arguments

- `d` : device instance
- `intensity` : the value from 1 to 16 controlling the brighness. 
    The modulator scales the average segment current in 16 steps.
"""
function set_intensity(d::AbstractNumDisplay, intensity::Int = 16)
    throw("Method is not applicable for $(typeof(d)) type")
end

"""
    write_digit(
        d::AbstractNumDisplay,
        value::UInt8,
        position::Int
    )

Writes a digit to the position. The result of the execution is changing one digit.

The result will depend on decode mode, see `decode_mode()` function.
The most significant bit sets the DP (dot) state.

In non-decode mode the bits 7-0 manage the sectors a, b, c, d, e, f, g.

In decode mode only bits 3-0 play a role. The sequence of numbers is the following: 0,1,2,3,4,5,6,7,8,9,-,E,H,L,P,blank

## Arguments

- `d` : object representing display device

- `value` : `UInt8` value updating the buffer value.

- `position` : number of digit to write starting from 1 which mean least significant digit.
    The maximal value depends on available digits, so it should be `<= length(indicator.digit_pins)`
"""
function write_digit(
    d::AbstractNumDisplay,
    value::UInt8,
    position::Int # starting from less significant
)
    throw("Method is not applicable for $(typeof(d)) type")
end

### high level methods

"""
    write_number(
        indicator::AbstractNumDisplay,
        number::Int,
        dp_position::Union{Int, Nothing} = nothing
    )

Writes the decimal value to the display.

## Arguments

- `indicator` : object representing display device

- `number` : decimal number. The maximal possible value depends on number of digits and will be checked.

- `dp_position` : position of digit starting from less significant digit or nothing.

## Example

```
# d is 4-digit display
write_number(d, 123)
# the result is _123

write_number(d, 1234)
# the result is 1234

write_number(d, 12345)
# throws an error
```
"""
function write_number(
    d::AbstractNumDisplay,
    number::Int,
    dp_position::Union{Int, Nothing} = nothing
)
    @assert 0 <= number < 10^size(d) "number $number cannot be displayed on $(size(d))-digits indicator"

    write_number(d, digits(number), dp_position)
end

"""
Writes several digits
Runs display in decode mode and display several digits
element in numer_vector must be Integers
"""
function write_number(
    d::AbstractNumDisplay,
    number_vector::AbstractArray{D},
    dp_position::Union{Int, Nothing} = nothing
) where D <: Union{Int, Nothing}
    l = length(number_vector)

    @assert 0 <= l <= size(d) "number_vector of length $l cannot be displayed on $(size(d))-digits indicator"
    set_limit(d, l)
    decode_mode(d)

    for i in 1:l
        num_i = number_vector[i] !== nothing ? number_vector[i] : 15
        is_dot = dp_position == i
        @assert 0 <= num_i <= 15 "number in vector must be between 0 and 15, got $num_i"

        digit_i = is_dot << 7 | num_i # dot coded by most significant bit
        write_digit(d, UInt8(digit_i), i)
    end
end

"""
works in segment-wise mode
set active segments DP A B C D E F G
"""
function write_symbols(
    d::AbstractNumDisplay,
    byte_vector::AbstractArray{UInt8},
)
    l = length(byte_vector)
    set_limit(d, l)
    decode_mode(d, 0x0)

    for i in 1:l
        write_digit(d, byte_vector[i], i)
    end
end

function write_symbols(
    d::AbstractNumDisplay,
    symbol_vector::AbstractArray{Char},
)
    # CHAR_TRANSLATOR
    byte_vector = [get(CHAR_TRANSLATOR, char, 0b00000000) for char in symbol_vector]
    write_symbols(d, byte_vector)
end

function write_symbols(
    d::AbstractNumDisplay,
    s::String
)
    symbol_vector = collect(s)
    write_symbols(d, reverse(symbol_vector))
end
