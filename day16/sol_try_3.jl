const LINE_TEMPLATE = "Valve ????? has flow rate=?????; tunnel lead to valve ?????"
const LINE_SPLITS = split(LINE_TEMPLATE, "?????", keepempty=false)

function load_file(file)
    lines = readlines(file)

    names = Set{String}()
    connecteds = Dict{String, Vector{String}}()
    flow_rates =  Dict{String, Int}()

    foreach(lines) do line
         name, flow_rate, connected = parse_line(line)
        push!(names, name)
        connecteds[name] = connected
        flow_rates[name] = flow_rate
    end

    return names, connecteds, flow_rates
end

function parse_line(line)
    org_line = line

    line = replace(line, "tunnels" => "tunnel", "valves" => "valve", "leads" => "lead")

    for split in LINE_SPLITS
        line = replace(line, split => "?????")
    end

    fields = split(line, "?????", keepempty=false)

    length(fields) == 3 || error("Found $(length(fields)) number of fields instead of \
                                 3 for \"$org_line\".")

    return string(fields[1]), parse(Int, fields[2]), string.(strip.(split(fields[3], ",")))
end

function get_distances_from(from::T, connected::Dict{T, U}) where {T, U}
    queue = [(from, 0)]
    visited_elements = Set{T}()

    to_distances = Dict{T, Int}()
    
    while !isempty(queue)
        current_element, current_distance = popfirst!(queue)

        current_element in visited_elements && continue
        push!(visited_elements, current_element)

        to_distances[current_element] = current_distance

        foreach(connected[current_element]) do neighbor_element
            push!(queue, (neighbor_element, current_distance + 1))
        end
    end

    if length(to_distances) != length(connected)
        error("Could not find distances to all the elements from $from.")
    end

    return to_distances
end

function get_distances(connected::Dict{T, U}) where {T, U}
    distances = Dict{Tuple{T, T}, Int}()

    for from in keys(connected)
        from_distances = get_distances_from(from, connected)
        foreach(keys(from_distances)) do to
            distances[(to, from)] = from_distances[to]
        end
    end

    return distances
end

function find_most_released(
        open_valves, closed_valves, distances, flow_rates, time_limit; 
        starting = "AA"
    )

    if !allunique(open_valves) 
        error("Openen valves, $open_valves, are not unique, you tried to open a valve twice!")
    end
    time_taken = total_time_opening(open_valves, distances, starting)

    if time_taken > time_limit
        return amount_released(open_valves[1:end-1], distances, time_limit, flow_rates)
    elseif isempty(closed_valves) || time_taken == time_limit
        return amount_released(open_valves, distances, time_limit, flow_rates)
    end

    return maximum(collect(closed_valves)) do closed_valve
        new_open_valves = [open_valves; closed_valve]
        new_closed_valves = setdiff(closed_valves, [closed_valve])
        find_most_released(
                           new_open_valves, new_closed_valves, distances, flow_rates, time_limit; 
                           starting = starting
                          )
    end
end

function get_steps_from_to(open_valves, distances, starting = "AA")
    map([starting; open_valves], open_valves) do from, to
        distances[(to, from)]
    end
end

function total_steps(open_valves, distances, starting = "AA")
    sum(get_steps_from_to(open_valves, distances, starting), init = zero(eltype(values(distances))))
end

function total_time_opening(open_valves, distances, starting = "AA")
    total_steps(open_valves, distances, starting) + length(open_valves)
end

function amount_released(open_valves, distances, time_limit, flow_rates)
    times_taken = cumsum(1 .+ get_steps_from_to(open_valves, distances))
    times_left = time_limit .- times_taken
    return mapreduce(+, open_valves, times_left) do open_valve, time_left
        flow_rates[open_valve] * time_left
    end
end


function solve_2(file, timelimit = 26)
    names, connected, flowrates = load_file(file)

    T = eltype(names)
    # queue = [(elephant_valves = [""], valves = ["AA"], time = 0)]

    max_released = -1
    queue = [(valves = T["AA"], releasing = T[], time = 0, released = 0)]
    
    while !isempty(queue)
        # @info getproperty.(queue, :released)
        # @info getproperty.(queue, :time)
        (; valves, time, releasing, released) = popfirst!(queue)

        time == timelimit && continue
        # released < max_released && continue
        
        not_releasing = collect(setdiff(names, releasing))
        # max_releasable = released + mapreduce(+, not_releasing) do nr_valve
        #     releasing_time = timelimit - time - 2
        #     flowrates[nr_valve] * releasing_time
        # end
        max_releasable = released
        max_releasable += sum(releasing, init = 0) do r_valve
            releasing_time = timelimit - time
            flowrates[r_valve] * releasing_time
        end

        sort!(not_releasing, by = v -> flowrates[v], rev = true)
        max_releasable += mapreduce(+, not_releasing,
                                    1:length(not_releasing), init = 0
                                   ) do nr_valve, step
            releasing_time = max(timelimit - time - 2*step, 0)
            flowrates[nr_valve] * releasing_time
        end
        
        max_releasable < max_released && continue

        max_released = max(max_released, released)

        current_valve = valves[end]

        released += sum(releasing, init = 0) do r_valve
            flowrates[r_valve]
        end
        
        # stepping
        foreach(connected[current_valve]) do neighbor_valve
            push!(queue, (
                          valves = [valves; neighbor_valve], 
                          releasing = releasing, 
                          time = time + 1, 
                          released = released
                         )
                 )
        end
        
        # opening if able to
        if flowrates[current_valve] > 0 && !in(current_valve, releasing)
            push!(queue, (
                          valves = valves, 
                          releasing = [releasing; current_valve], 
                          time = time + 1, 
                          released = released
                         )
                 )
        end
    end

    println("The maximum released with $file, was $max_released.")
end

solve_2("test.txt", 30)
