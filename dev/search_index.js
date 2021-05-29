var documenterSearchIndex = {"docs":
[{"location":"api/#API-references","page":"API","title":"API references","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"Modules = [NumDisplay]\nOrder   = [:type, :function]","category":"page"},{"location":"api/#NumDisplay.DisplayBCD","page":"API","title":"NumDisplay.DisplayBCD","text":"struct DisplayBCD <: AbstractNumDisplay\n    sectors_pins::AbstractVector{Int}   # pin numbers starting from less significant\n    input_pins::Tuple{Int,Int,Int,Int}  # pin numbers for binary code starting from less significant\n    dp_pin::Union{Int, Nothing}         # pin changing dot state\n    buffer::AbstractVector{UInt8}       # internal storage of digits values\n    dp_buffer::AbstractVector{UInt8}\n    usDelay::Int                        # duration of period when sector is on\nend\n\n\n\n\n\n","category":"type"},{"location":"api/#NumDisplay.DisplayBCD-2","page":"API","title":"NumDisplay.DisplayBCD","text":"function DisplayBCD(\n    sectors_pins::AbstractVector{Int},\n    input_pins::Tuple{Int,Int,Int,Int},\n    dp_pin::Union{Int, Nothing} = nothing;\n    fps::Int = 1000\n)\n\nCreates device representing numerical display with several digits under control of the BCD chip. The number of display digits equal to sectors_pins count.\n\nArguments\n\nsectors_pins : Vector of GPIO pin numbers connected to anode. The HIGH state means the digit is on. LOW means off.   The first pin in array should manage the less significant digit.\ninput_pins : Tuple consisting of GPIO numbers representing the 4-bit code of a digit.   The first pin in tuple is less significant number.\ndp_pin : Number of pin connected to dot LED (DP)\nfps : frame rate (frames per second). The digits in display are controlled by impulses of sectors_pins.    This argument sets the width of one impuls.    If fps=1000 the width will be recalculated as 1/1000 = 1e-3 second or 1e3 microsecond.   The default value is 1000 Hz.\n\n\n\n\n\n","category":"type"},{"location":"api/#NumDisplay.clean-Tuple{DisplayBCD}","page":"API","title":"NumDisplay.clean","text":"clean(indicator::DisplayBCD)\n\nDisplay empty sectors.\n\nArguments\n\nindicator : object representing display device\n\n\n\n\n\n","category":"method"},{"location":"api/#NumDisplay.stop-Tuple{DisplayBCD}","page":"API","title":"NumDisplay.stop","text":"stop(indicator::DisplayBCD)\n\nStop device and reset the the initial state.\n\nArguments\n\nindicator : object representing display device\n\n\n\n\n\n","category":"method"},{"location":"api/#NumDisplay.update-Tuple{DisplayBCD}","page":"API","title":"NumDisplay.update","text":"update(indicator::DisplayBCD)\n\nShow the content of indicator.buffer to the display. This function is used internaly by write... methods to update the display.\n\nArguments\n\nindicator : object representing display device\n\n\n\n\n\n","category":"method"},{"location":"api/#NumDisplay.write_digit-Tuple{DisplayBCD, Union{Nothing, UInt8}, Int64}","page":"API","title":"NumDisplay.write_digit","text":"function write_digit(\n    indicator::DisplayBCD,\n    digit::Union{UInt8, Nothing},\n    position::Int\n)\n\nWrites a digit to the position. The result of the execution is changing one digit in a particular sector. \n\nArguments\n\nindicator : object representing display device\ndigit : decimal value from 0 to 9 or nothing. The last means an empty sector.       Values from 10 to 14 are also possible here but results to miningless symbols.       Value 15 means an empty sector and it is the same as nothing.\nposition : number of sector to write starting from 1 which mean less signifacant digit.       The maximal value depends on available sectors, so it should be <= length(indicator.digit_pins)\n\n\n\n\n\n","category":"method"},{"location":"api/#NumDisplay.write_dp-Tuple{DisplayBCD, UInt8, Int64}","page":"API","title":"NumDisplay.write_dp","text":"function write_dp(\n    indicator::DisplayBCD,\n    dp_value::UInt8,\n    dp_position::Int\n)\n\nWrites a dot symbol to the position. The result of the execution is changing one dot in a particular sector. \n\nArguments\n\nindicator : object representing display device\ndp_value : value 0 or 1 to get dot OFF or ON.\nposition : number of sector to write starting from 1 which mean less signifacant digit.       The maximal value depends on available sectors, so it should be <= length(indicator.digit_pins)\n\n\n\n\n\n","category":"method"},{"location":"api/#NumDisplay.write_number","page":"API","title":"NumDisplay.write_number","text":"write_number(\n    indicator::DisplayBCD,\n    number::Int,\n    dp_position::Union{Int, Nothing} = nothing\n)\n\nWrites the decimal value to the display.\n\nArguments\n\nindicator : object representing display device\nnumber : decimal number. The maximal possible value depends on number of sectors and will be checked.\n\nExample\n\n# d is 4-digit (sector) display\nwrite_number(d, 123)\n# the result is _123\n\nwrite_number(d, 1234)\n# the result is 1234\n\nwrite_number(d, 12345)\n# throws an error\n\n\n\n\n\n","category":"function"},{"location":"api/#NumDisplay.write_number-Union{Tuple{D}, Tuple{DisplayBCD, AbstractArray{D, N} where N}, Tuple{DisplayBCD, AbstractArray{D, N} where N, Union{Nothing, Int64}}} where D<:Union{Nothing, UInt8}","page":"API","title":"NumDisplay.write_number","text":"function write_number(\n    indicator::DisplayBCD,\n    digit_vector::AbstractArray{D},\n    dp_position::Union(Int,Nothing) = nothing\n) where D <: Union{UInt8, Nothing}\n\nWrites several digits to the positions. The result of the execution is updating the whole number. If digit_vector is shorter than number of sectors the rest sectors will be empty.\n\nArguments\n\nindicator : object representing display device\ndigitvector : vector of decimal values from 0 to 9 or nothing. The same meaning as digit in `writedigit()`.   The first element of vector will be writte to the less significant sector, etc.\ndp_position : position of dot in display\n\nExample\n\n# d is 4-digit (sector) display\nwrite_number(d, [1,2])\n# the result is __321\n\nwrite_number(d, [1,2,3,4])\n# the result is 4321\n\nwrite_number(d, [1,2,3,4,5,6])\n# the result is 4321\n\n\n\n\n\n","category":"method"},{"location":"bcd/#BCD-approach","page":"BCD","title":"BCD approach","text":"","category":"section"},{"location":"bcd/","page":"BCD","title":"BCD","text":"BCD is a Binary-Coded Decimal chip which can be used to manage display with several digits.","category":"page"},{"location":"bcd/","page":"BCD","title":"BCD","text":"The chip transforms the binary code (4 bits: A, B, C, D) to the 7-segment (a,b,c,d,e,f,g) LED states representing decimal number. If you use the indicator with common anode you need to switch the sectors by additional signal: one pin for one sector. ","category":"page"},{"location":"bcd/","page":"BCD","title":"BCD","text":"The method requires 4 pins to display decimal and additionally one pin per sector. For example 4-sector-display requires 4 + 4 = 8 GPIO pins.  8-sector-display requires 4 + 8 = 12 GPIO pins.","category":"page"},{"location":"bcd/","page":"BCD","title":"BCD","text":"If you use dot on display you need the additional pin. For example 4-sector-display requires 4 + 1 + 4 = 9 GPIO pins. ","category":"page"},{"location":"bcd/","page":"BCD","title":"BCD","text":"Common anode chips examples","category":"page"},{"location":"bcd/","page":"BCD","title":"BCD","text":"246 : SN54246, SN74246\n247 : SN54247, SN74247\nLS247 : SN54LS247, SN74LS247(*)\nLS248 : SN54LS248, SN74LS248","category":"page"},{"location":"bcd/","page":"BCD","title":"BCD","text":"(*) was tested","category":"page"},{"location":"bcd/#Usage","page":"BCD","title":"Usage","text":"","category":"section"},{"location":"bcd/","page":"BCD","title":"BCD","text":"Without dot","category":"page"},{"location":"bcd/","page":"BCD","title":"BCD","text":"using NumericDisplay\nd = DisplayBCD(\n    [       # pins to on/off sectors\n        27, # less significant decimal digit\n        22,\n        10,\n        9   # most significant decimal digit\n    ],\n    (      # pins connected to chip to transform bits to decimal number\n        2, # A (less significant bit)\n        3, # B\n        4, # C\n        17 # D (most significant bit)\n    )\n)\n\nwrite_number(d, 666) # display _666\nsleep(1)\nstop(d)              # display nothing","category":"page"},{"location":"bcd/","page":"BCD","title":"BCD","text":"With dot","category":"page"},{"location":"bcd/","page":"BCD","title":"BCD","text":"using NumericDisplay\nd = DisplayBCD(\n    [       # pins to on/off sectors\n        27, # less significant decimal digit\n        22,\n        10,\n        9   # most significant decimal digit\n    ],\n    (      # pins connected to chip to transform bits to decimal number\n        2, # A (less significant bit)\n        3, # B\n        4, # C\n        17 # D (most significant bit)\n    ),\n    11     # pin to control dot\n)\n\nwrite_number(d, 666) # display _666\nsleep(1)\nwrite_number(d, 666, 2) # display _66.6\nsleep(1)\nstop(d)              # display nothing","category":"page"},{"location":"bcd/#Circuit","page":"BCD","title":"Circuit","text":"","category":"section"},{"location":"bcd/","page":"BCD","title":"BCD","text":"Without dot","category":"page"},{"location":"bcd/","page":"BCD","title":"BCD","text":"(Image: bcd-scheme)","category":"page"},{"location":"bcd/","page":"BCD","title":"BCD","text":"(Image: Watch the video)","category":"page"},{"location":"bcd/","page":"BCD","title":"BCD","text":"Notes","category":"page"},{"location":"bcd/","page":"BCD","title":"BCD","text":"Here I was using the NPN transistors to switch digits because I had them but MOSFETs was also possible there.\nTo use the dot symbol (which is also available on the indicator) it is required to add one additional pin.","category":"page"},{"location":"#NumericDisplay","page":"Home","title":"NumericDisplay","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Raspberry Pi package for controlling the 7-segment numeric displays written in Julia.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The package supports several ","category":"page"},{"location":"#Approaches","page":"Home","title":"Approaches","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"BCD is a Binary-Coded Decimal chip which can be used to manage display with several digits. See DisplayBCD.","category":"page"},{"location":"#Installation","page":"Home","title":"Installation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Julia must be installed on Raspberry Pi.  I have tested on v1.1.0 which can be installed with:","category":"page"},{"location":"","page":"Home","title":"Home","text":"sudo apt update\nsudo apt install julia","category":"page"},{"location":"","page":"Home","title":"Home","text":"The package can be installed from Julia environment with:","category":"page"},{"location":"","page":"Home","title":"Home","text":"] add https://github.com/metelkin/NumDisplay.jl.git","category":"page"},{"location":"#Notes","page":"Home","title":"Notes","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"To run the code you need the full access to GPIO. Run it under sudo privileges.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Example running the code from \"test/run.jl\".","category":"page"},{"location":"","page":"Home","title":"Home","text":"sudo julia --project=. test/run.jl","category":"page"}]
}
