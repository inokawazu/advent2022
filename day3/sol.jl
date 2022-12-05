function get_input(file)
    return map(strip, readlines(file))
end

function to_sacks(line::AbstractString)
    l = length(line)
    return line[1:l÷2], line[l÷2+1:end]
    # return collect(line[1:l÷2]), collect(line[l÷2:end])
end

function common_item(sack1, sack2)
    shared = intersect(sack1, sack2)
    @assert length(shared) == 1
    return shared[1]
end

const PRIORITIES = Dict(['a':'z' .=> 1:26; 'A':'Z' .=> 27:52])
function priority(item::Char)
    p = get(PRIORITIES, item, nothing)
    isnothing(p) && throw(ErrorException("$p is not a correct item, and has not priority."))
    return p
end

let inlines = get_input("input.txt")
    sacks = to_sacks.(inlines)
    shareds = map(sacks) do (sack1, sack2)
        common_item(sack1, sack2)
    end
    shared_priorities = priority.(shareds) 
    println("The total priority of shared items is $(sum(shared_priorities))")
end

#############################################

function common_item(sacks::AbstractVector)
    shared = reduce(intersect, sacks)
    @assert length(shared) == 1
    return shared[1]
end

let inlines = get_input("input.txt")
    # @show inlines
    groups = Iterators.partition(inlines, 3)
    # shareds = common_item.(groups)
    # @show shareds
    total_priorities = mapreduce(priority∘common_item, +, groups)
    println("The total priority for 3 grouped shared items is $total_priorities")
end
