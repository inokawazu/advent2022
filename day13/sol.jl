function load_file(file)
    lines = readlines(file)

    pairs = []
    while !isempty(lines)
        line = popfirst!(lines)

        isempty(line) && continue

        push!(pairs, (parse_line(line), parse_line(popfirst!(lines))))
    end

    return pairs
end

islist(s::AbstractString) = startswith(s, "[") && endswith(s, "]")
isint(s::AbstractString) = all(isdigit, s)

function parse_line(line::AbstractString)
    islist(line) || error("line must start with [ and end with ]")
    
    split_chop_line = split_up_line(line)

    out = map(split_chop_line) do entry
        if islist(entry)
            parse_line(entry)
        elseif isint(entry)
            parse(Int, entry)
        else
            error("Found a entry that is not classifiable: $entry")
        end
    end

    return out
end

function split_up_line(line)
    chop_line = chop(line, head = 1, tail = 1)
    chars = collect(chop_line)

    out = String[]
    
    while !isempty(chars)
        char = popfirst!(chars)
        if isdigit(char)
            next_non_digit_i = findfirst(!isdigit, chars)
            next_non_digit_i = isnothing(next_non_digit_i) ? 1 : next_non_digit_i

            next_ent = char * join(popfirst!(chars) for _ in 1:next_non_digit_i-1)
            push!(out, next_ent)
        elseif char == ','
            continue
        elseif char == '['
            to_closing = find_get_to_closing!(chars)
            next_ent = char * join(to_closing)
            push!(out, next_ent)
        else
            error("Unreachable")
        end
    end

    return out
end

function find_get_to_closing!(chars)
    net_bracket = -1
    out = Char[]
    while net_bracket!= 0
        isempty(chars) && error("Found no closing bracket!")

        char = popfirst!(chars)

        if char == '['
            net_bracket -= 1
        elseif char == ']'
            net_bracket += 1
        end

        push!(out, char)
    end

    return out
end

@enum OrderResult Right Wrong Undecided

PRINT_LEVEL = Ref(0)
COMPARE_VERBOSE = Ref(false)
LEVEL_STR = " - "

function compare(i1::Integer, i2::Integer)
    result = if i1 == i2 
        Undecided
    elseif i1 > i2 
        Wrong 
    elseif i1 < i2 
        Right 
    end

    COMPARE_VERBOSE[] && println(LEVEL_STR^PRINT_LEVEL[], "$i1 ~ $i2: $result")

    return result
end

function compare(v1::Vector, i2::Integer)
    COMPARE_VERBOSE[] && println(LEVEL_STR^PRINT_LEVEL[], "$v1 ~ $i2: Converting")
    return compare(v1, [i2])
end

function compare(i1::Integer, v2::Vector)
    COMPARE_VERBOSE[] && println(LEVEL_STR^PRINT_LEVEL[], "$i1 ~ $v2: Converting")
    return compare([i1], v2)
end

function compare(v1::Vector, v2::Vector)
    cv1 = copy(v1)
    cv2 = copy(v2)

    local result = Undecided
    COMPARE_VERBOSE[] && println(LEVEL_STR^PRINT_LEVEL[], "$v1 ~ $v2: Comparing")

    PRINT_LEVEL[] += 1
    while !isempty(cv1) && !isempty(cv2)
        result = compare(popfirst!(cv1), popfirst!(cv2))
        result != Undecided && break
    end
    PRINT_LEVEL[] -= 1

    result != Undecided && return result

    result = if isempty(cv1) && isempty(cv2)
        Undecided
    elseif isempty(cv1)
        Right
    elseif isempty(cv2)
        Wrong
    else
        error("Unreachable")
    end

    COMPARE_VERBOSE[] && println(LEVEL_STR^PRINT_LEVEL[], " $cv1 ~ $cv2 becoming empty with $result")

    return result
end

const COMPARE_SOLVE_1_VERBOSE = Ref(false)

function solve_1(file)
    pairs = load_file(file)
    index_sum = sum(enumerate(pairs), init = big"0") do ip
        i, p = ip
        COMPARE_SOLVE_1_VERBOSE[] && println("Pair $i")
        r = compare(p...)
        COMPARE_SOLVE_1_VERBOSE[] && println("result $r")
        COMPARE_SOLVE_1_VERBOSE[] && println("="^10)
        r == Undecided && error("Found Undecided in the top level.")
        r == Right ? i : 0
    end

    println("For the sum of the indices for $file, the result is $index_sum.")
end

# COMPARE_SOLVE_1_VERBOSE[] = true
# COMPARE_VERBOSE[] = true
solve_1("input.txt")
