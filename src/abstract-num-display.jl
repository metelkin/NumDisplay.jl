abstract type AbstractNumDisplay end

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
