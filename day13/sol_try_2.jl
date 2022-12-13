function load_file(file)
    lines = strip.(readlines(file))

    filter!(!isempty, lines)

    Iterators.partition(parse_list.(lines), 2)
end

print_pair(x) = print(x)
function print_pair(v::AbstractVector)
    print("[")
    for (i,e) in enumerate(v)
        print_pair(e)
        i != length(v) && print(", ")
    end
    print("]")
end

function print_pair(x::Tuple{Any, Any})
    print("(")
    print_pair(x)
    print(", ")
    print_pair(x)
    print(")")
end

function println_pair(x)
    print_pair(x)
    println()
end

islist(s::AbstractString) = startswith(s, "[") && endswith(s, "]")
isint(s::AbstractString) = all(isdigit, s)

function parse_list(list::AbstractString)
    islist(list) || error("$list is not a valid list, must end with ] and start with ]")

    chomp_list = chop(list, head = 1, tail = 1)

    out = []

    i = 1
    while i <= length(chomp_list)
        c = chomp_list[i]
        if isdigit(c)
            i, int = get_int(i, chomp_list)
            push!(out, int)
        elseif c == ','
            i += 1
        elseif c == '['
            i, sub_list = get_list(i, chomp_list)
            push!(out, parse_list(sub_list))
        end
    end

    out .= out
    return out
end

function get_int(i::Integer, chomp_list::AbstractString)
    j = i + 1
    while j <= length(chomp_list) && !(chomp_list[j] in "[],")
        j += 1
    end
    return j, parse(Int, chomp_list[i:j-1])
end

function get_list(i::Integer, chomp_list::AbstractString)
    j = i + 1
    net_brak = -1

    while j <= length(chomp_list) && net_brak != 0
        c = chomp_list[j]
        if c == '['
            net_brak -= 1
        elseif c == ']'
            net_brak += 1
        end
        j += 1
    end

    net_brak != 0 && error("Did not find a closing brack for $chomp_list.")

    return j, chomp_list[i:j-1]
end

@enum Order Right Wrong Undecided

compare(i::Integer, j::Integer) = i == j ? Undecided : (i < j ? Right : Wrong)

compare(i::Integer, w::Vector) = compare([i], w)
compare(v::Vector, j::Integer) = compare(v, [j])

function compare(v::Vector, w::Vector)
    length_result = compare(length(v), length(w))
    
    element_result = Undecided
    for (l, r) in zip(v, w)
        element_result = compare(l, r)
        element_result != Undecided && return element_result
    end

    return length_result
end

function solve_1(file)
    pairs = load_file(file)
    
    index_sum = sum(enumerate(pairs)) do ip
        i, p = ip
        r = compare(p...)
        r == Undecided && error("Found Undecided in the top level.")
        # println("Index: $i, Result: $r")
        r == Right ? i : 0
    end
    println("The index sum for $file is $index_sum.")
end

# foreach(println_pair, load_file("test.txt"))
# solve_1("test.txt")

solve_1("input.txt")


#######################################################

function compare_lt(l, r)
    r = compare(l, r)
    r == Undecided && error("Cannot sort if Undecided is found. Comparing $l ~ $r.")

    return r == Right
end

function solve_2(file; verbose = false)
    packets = load_file(file) |> Iterators.flatten |> collect
    push!(packets, [[2]], [[6]])

    verbose && println_pair.(packets)
    verbose && println("="^50)

    sorted_packets = sort(packets, lt = compare_lt)

    verbose && println_pair.(sorted_packets)

    index1 = findfirst(==([[2]]), sorted_packets)
    index2 = findfirst(==([[6]]), sorted_packets)
    index_product = index1 * index2

    println("The decoder key for $file, is $index1 × $index2 = $index_product.")
end

solve_2("input.txt", verbose = false)
