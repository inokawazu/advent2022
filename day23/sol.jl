function load_file(file)
    lines = readlines(file)
    l = length(lines)
    mapreduce(vcat, lines, 1:l) do line, row
        y = l - row 
        
        [CartesianIndex(col - 1, y) for (col, elem) in enumerate(line) 
         if elem == '#']
    end
end

# println(load_file("test.txt"))

const DIRECTIONS = CartesianIndex.((
                                    (+0,+1),
                                    (+0,-1),
                                    (-1,+0),
                                    (+1,+0),
                                   ))

const PERPENDICULARS = CartesianIndex.((
                                        (-1,+0),
                                        (+1,+0),
                                        (+0,-1),
                                        (+0,+1),
                                       ))

const UNITI = CartesianIndex(1, 1)

function proposal_order(round)
    nd = length(DIRECTIONS)
    return collect(mod1.(round:round+nd-1, nd))
end

function proposal_directions(round)
    return DIRECTIONS[proposal_order(round)]
end

function looking_directions(direction_index)
    d = DIRECTIONS[direction_index]
    p = PERPENDICULARS[direction_index]
    return (d-p, d, d+p)
end

function has_neighbors(position, all_positions)
    neighboring_positions = Set(setdiff(position-UNITI:position+UNITI))
    pop!(neighboring_positions, position)

    return !isempty(intersect(neighboring_positions, all_positions))
end
# function has_neighbors(position, all_positions)
#     neighboring_positions = setdiff(position-UNITI:position+UNITI, [position])
#     return any(neighboring_positions) do np
#         np in all_positions
#     end
# end

function print_locations(loc_set)
    minI, maxI = extrema(loc_set)
    map_arr = [I in loc_set ? "#" : "." for I in minI:maxI]
    foreach(println∘join, Iterators.reverse(eachrow(permutedims(map_arr))))
    println()
end

function run_round!(loc_set, round; verbose = false)
    T = eltype(loc_set)
    # first half of round
    # elves without elves around them will not propose
    proposing_pos = filter(p -> has_neighbors(p, loc_set), loc_set)
    isempty(proposing_pos) && return

    proposed_pos = Tuple{T, T}[]
    # accoding to the current order propossing direction order, the elves
    # propose spots to move to
    verbose && @info "Elves are at $(Tuple.(loc_set))" 

    for direction_index in proposal_order(round)
        ld = looking_directions(direction_index)
        verbose && @info Tuple.(ld)
        ld_pps = filter(proposing_pos) do pp
            verbose && @info "Elf at $(Tuple(pp)) is looking "
            verbose && @info "to $(Tuple.(Ref(pp) .+ ld))"
            all(!in(loc_set), Ref(pp) .+ ld)
        end

        setdiff!(proposing_pos, ld_pps)
        foreach(ld_pps) do p
            push!(proposed_pos, (p, p + DIRECTIONS[direction_index]))
        end
    end

    # if elves are going to same position they dont move
    i = 1
    while i <= length(proposed_pos)

        dup_mask = map(1:length(proposed_pos)) do j
            j > i && (proposed_pos[i][2] == proposed_pos[j][2])
        end

        dup_mask[i] = any(dup_mask)
        has_overlap = dup_mask[i]

        (verbose && has_overlap) && 
        @info "Found colliding elves goint to $(proposed_pos[i][2])"

        deleteat!(proposed_pos, dup_mask)

        if !has_overlap 
            i += 1
        end
    end

    # do moves
    for (old_pos, new_pos) in proposed_pos
        verbose && @info "Elf $(Tuple(old_pos)) → $(Tuple(new_pos))"
        pop!(loc_set, old_pos)
        push!(loc_set, new_pos)
    end
    verbose && print_locations(loc_set)

    verbose && @info "======================"
end

function solve_1(file, nrounds = 10; verbose = false)
    verbose && println(read(file, String))
    # loc_vec = load_file(file)
    loc_set = Set(load_file(file))

    verbose && print_locations(loc_set)

    for round in 1:nrounds
        run_round!(loc_set, round; verbose = verbose)
    end

    minI, maxI = extrema(loc_set)

    empty_tiles = count(!in(loc_set), minI:maxI)
    println("For $file, the number of empty tiles spanned by the elves is $empty_tiles")
    empty_tiles
end

# solve_1("small.txt")
# solve_1("test.txt")
solve_1("input.txt")

function solve_2(file; verbose = false)
    loc_set = Set(load_file(file))
    round = 1
    while true
        before = copy(loc_set)
        run_round!(loc_set, round; verbose = verbose)

        # @info "ROUND = $round"
        
        if issetequal(before, loc_set)
            break
        else
            round += 1
        end
    end

    println("For $file, the number of rounds taken to see not change is $round rounds.")
    round
end

# solve_2("test.txt")
# solve_2("test.txt")
solve_2("input.txt")
