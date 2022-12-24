const Location{T} = Tuple{T, T}

const UP::Location{Int}    = (-1,  0)
const DOWN::Location{Int}  = ( 1,  0)
const LEFT::Location{Int}  = ( 0, -1)
const RIGHT::Location{Int} = ( 0,  1)

get_directions() = (UP, DOWN, LEFT, RIGHT)

function load_file(file)
    
    lines = readlines(file)
    last_location = (length(lines) - 1, length(lines[1]) - 2)
    return mapreduce(vcat, enumerate(lines[1+1:end-1])) do (row, line)
        map(enumerate(line[1+1:end-1])) do (col, elem)
            # @info (row, col, elem)
                if elem == '<'
                    (direction = LEFT , location = (row, col))
            elseif elem == '^'
                    (direction = UP   , location = (row, col))
            elseif elem == '>'
                    (direction = RIGHT, location = (row, col))
            elseif elem == 'v'
                    (direction = DOWN , location = (row, col))
            elseif elem == '.'
                missing
            else
                error("$elem is not recognized.")
            end
        end
    end |> skipmissing |> collect, last_location
end

function get_neighbors(location::Location)
    Iterators.map(get_directions()) do direction
        direction .+ location
    end
end

struct Blizzard
    state
    set
end

function print_blizzard(b::Blizzard, bounds)
    print_arr = fill('.', bounds[2])
    for (;direction, location) in b.state
        d = direction
        c = print_arr[location...]
        print_arr[location...] = (c != '.')   ? '2' :
                                 (d == UP)    ? '^' :
                                 (d == DOWN)  ? 'v' :
                                 (d == LEFT)  ? '<' : '>'
    end
    
    foreach(println∘join, eachrow(print_arr))
    # for I in CartesianIndex(bounds[1]):CartesianIndex(bounds[2])
    # end
end

function Blizzard(state)
    return Blizzard(state, Set(location for (;location) in state))
end

function next_blizzard(bs::Blizzard, bounds)
    return Blizzard(next_blizzard(bs.state, bounds))
end

blizzard_move(location, direction, upperbound) = @. mod1(location + direction, upperbound)

function next_blizzard(blizzard, bounds)
    # new_blizzard = copy(blizzard)
    new_blizzard = empty(blizzard)
    sizehint!(new_blizzard, length(blizzard))

    _, upperbound = bounds
    
    for (; location, direction) in blizzard
        new_location  = blizzard_move(location, direction, upperbound)
        new_direction = direction
        # new_blizzard[new_location] = new_direction
        push!(
              new_blizzard, 
              (direction = new_direction, location = new_location)
             )
    end
    return new_blizzard
end

Base.in(location, b::Blizzard) = in(location, b.set)

isinbounds(location::Location, bounds) = all(bounds[1] .<= location .<= bounds[2])

function test_blizzard_move(file)
    _, last_location = load_file(file)

    bounds = ((1,1), last_location .+ (-1, 0))

    @show direction = RIGHT
    @show upperbound = bounds[2]
    @show location = (2, 1)
    for _ in 1:10
        @show location = blizzard_move(location, direction, upperbound)
    end
end

function min_blizard_trek_rounds(
        initial_blizzard_state, 
        start_location, 
        last_location,
        bounds;
    verbose = false, showmap = false)

    verbose && @info "The bounds are $bounds."
    verbose && @info "The finishing location is $last_location."

    initial_blizzard = Blizzard(initial_blizzard_state)
    blizzards = [next_blizzard(initial_blizzard, bounds)]

    verbose && @info "Making blizzard for 1"
    showmap && print_blizzard(blizzards[1],bounds)

    minimum_rounds = typemax(Int)

    state_queue = [(start_location, 0)]

    visited = Set{eltype(state_queue)}()

    while !isempty(state_queue)
        current_state = popfirst!(state_queue)
        current_location, current_round = current_state
        verbose && @info "The current location is $current_location, at $current_round."

        if current_state in visited
            error("Visited location round twice")
        end
        push!(visited, current_state)
        
        if current_location == last_location
            verbose && @info "FOUND THE END in $current_round rounds!"
            minimum_rounds = current_round
            break
        end

        next_round = current_round + 1
        while length(blizzards) < next_round
            verbose && @info "Making blizzard for $next_round."
            new_blizzard = next_blizzard(blizzards[end], bounds)
            showmap && print_blizzard(new_blizzard, bounds)
            push!(blizzards, new_blizzard)
        end
        
        candidate_locations = Iterators.flatten((
                                                 get_neighbors(current_location),
                                                 (current_location,)
                                                ))
        
        foreach(candidate_locations) do candidate_location
            # neighbor in visited && return
            candidate_state = (candidate_location, next_round)
            
            candidate_state in visited && return

            (
             isinbounds(candidate_location, bounds) || 
             candidate_location == last_location ||
             candidate_location == start_location
            ) || return

            for state in state_queue
                candidate_state == state && return
            end
            candidate_location in blizzards[next_round] && return

            push!(state_queue, (candidate_location, next_round))
        end
    end

    if minimum_rounds == typemax(typeof(minimum_rounds))
        error("Could not get to the finish.")
    end

    return minimum_rounds, blizzards[minimum_rounds].state
end


function solve_1(file; showmap = false, verbose = false)
    initial_blizzard_state, last_location = load_file(file)
    start_location = (0, 1)

    bounds = ((1,1), last_location .+ (-1, 0))

    minimum_rounds, _ = min_blizard_trek_rounds(initial_blizzard_state, 
                                                start_location, last_location,
                                                bounds;
                                                showmap=showmap, verbose=verbose)

    println("For $file the minimum number of rounds to get to end was $minimum_rounds.")
end

solve_1("test.txt")
solve_1("input.txt")

#######################

function solve_2(file; showmap = false, verbose = false)
    initial_blizzard_state, last_location = load_file(file)
    bounds = ((1,1), last_location .+ (-1, 0))
    start_location = (0, 1)

    verbose && @info "Starting to find rounds to the end the first time."

    rounds1, blizzard_ini_1 = min_blizard_trek_rounds(initial_blizzard_state, 
                                                      start_location, 
                                                      last_location, bounds;
                                                      showmap=showmap, verbose=verbose)

    verbose && @info "Starting to find the rounds from the end to the beginning."

    rounds2, blizzard_ini_2 = min_blizard_trek_rounds(blizzard_ini_1, 
                                                      last_location, 
                                                      start_location, bounds;
                                                      showmap=showmap, verbose=verbose)

    verbose && @info "Starting to find the rounds back to the end."

    rounds3, _ = min_blizard_trek_rounds(blizzard_ini_2, 
                                         start_location, 
                                         last_location, bounds;
                                         showmap=showmap, verbose=verbose)

    println("For $file the minimum number of rounds to get to the end twice was \
            $rounds1 + $rounds2 + $rounds3 =  $(rounds1 + rounds2 + rounds3).")
end

solve_2("test.txt")
solve_2("input.txt")
