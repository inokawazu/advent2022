const SNAFU_VALUES::Dict{Char, Int} = Dict(
                          '2' => +2,
                          '1' => +1,
                          '0' => +0,
                          '-' => -1,
                          '=' => -2,
                         )

const DECIMAL_VALUES::Dict{Int, Char} = Dict(
                                             +2 => '2',
                                             +1 => '1',
                                             +0 => '0',
                                             -1 => '-',
                                             -2 => '=',
                                            )

function snafu_to_decimal(snafu::String)
    return sum(
               5 ^ (i-1) * SNAFU_VALUES[c] 
               for (i, c) in enumerate(Iterators.reverse(snafu))
              )
end

load_file(file) = map(snafu_to_decimal, readlines(file))

get_snafu_values() = sort(collect(keys(DECIMAL_VALUES)))

function list_n_digit_snafu(n::Integer)
    n < 1 && error("n must be positive.")
    snafu_values = get_snafu_values()

    n == 1 && return map(sv -> DECIMAL_VALUES[sv], snafu_values)
    
    return mapreduce(vcat, snafu_values) do sv
        Ref(DECIMAL_VALUES[sv]) .* list_n_digit_snafu(n-1)
    end
end

max_snafu(place) = sum(5 ^ e * 2 for e in 0:place)

function convert_decimal_base(decimal::Integer, base::Integer, offset = 0)
    decimal < 0 && error("Can only convert positive numbers.")
    decimal == 0 && return [zero(decimal)]

    digits = []

    deficit = 0
    while decimal != 0
        quo, rem = divrem(decimal, base)

        # rem += deficit
        # deficit = 0

        if rem > base - offset 
            digit   = rem - base
            # deficit += 1
            decimal = quo + 1
        else
            digit   = rem
            decimal = quo
        end
        pushfirst!(digits, digit)
    end

    # @show digits
    return digits
end

function decimal_to_snafu(decimal::Integer)
    digit_values = convert_decimal_base(decimal, 5, 3)
    return getindex.(Ref(DECIMAL_VALUES), digit_values) |> join
end

 # foreach(list_n_digit_snafu(2)) do snafu
 #     decimal = snafu_to_decimal(snafu)
 #     decimal < 0 && return
 #     snafuback = decimal_to_snafu(decimal)
 #     println(snafu, " ~ " , decimal, " ~ ", snafuback)
 # end

# convert_decimal_base.(7, 3)
# convert_decimal_base.(8, 3)
# convert_decimal_base.(9, 3)
# convert_decimal_base.(8:-1:0, 2)

# function decimal_to_snafu(decimal::Integer)
#     decimal < 0 && error("Can only convert positive numbers.")

#     ndigits = -1
#     for place in Iterators.countfrom(0)
#         decimal <= max_snafu(place) || continue
#         ndigits = place + 1
#         break
#     end
    
#     @show decimal, ndigits

#     snafu_values = get_snafu_values()
#     i = findfirst(snafu_values) do sv
#         decimal - 5 ^ (ndigits) * sv <= 0
#     end
#     @show DECIMAL_VALUES[snafu_values[i]]
# end

# decimal_to_snafu(11)

# foreach(println, load_file("test.txt"))
# foreach(readlines("test.txt")) do line
#     println(line, " = ", snafu_to_decimal(line))
# end

# using InteractiveUtils
# @code_warntype snafu_to_decimal("12")

# decimal_to_snafu(123)

function solve_1(file)
    decimals = load_file(file)
    summed_snafu = decimal_to_snafu(sum(decimals))
    println("For $file the summed number if snafu is $summed_snafu.")
end

solve_1("test.txt")
solve_1("input.txt")
