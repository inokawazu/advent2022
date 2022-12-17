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

function solve_1(file, timelimit = 30)
    names, connected, flowrates = load_file(file)

    # foreach(println, flowrates)
    closed_valves = collect(names)
    filter!(closed_valves) do closed_valve
        flowrate = flowrates[closed_valve]
        flowrate > 0
    end
    # foreach(println, closed_valves)

    distances = get_distances(connected)
    # foreach(println, distances)

    T = eltype(closed_valves)
    released_amount = find_most_released(T[], closed_valves, distances, flowrates, timelimit)

    println("For $file, the most released pressure is $released_amount.")
end

# solve_1("input.txt")

############################################

function permutations(iter, n)
    if n == 1
        T = eltype(iter)
        return (T[element] for element in iter)
    end
    return Iterators.flatten(
                             (
                              (
                               [element; sub_iter] 
                               for sub_iter in permutations(setdiff(iter, [element]), n - 1)
                              ) 
                              for element in iter
                             )
                            )
end

function find_most_released_2(open_valves, closed_valves, distances, flow_rates, time_limit; starting = "AA")

    if !allunique(open_valves) 
        error("Openen valves, $open_valves, are not unique, you tried to open a valve twice!")
    end
    time_taken = total_time_opening(open_valves, distances, starting)

    if time_taken > time_limit
        return amount_released(open_valves[1:end-1], distances, time_limit, flow_rates), open_valves
    elseif isempty(closed_valves) || time_taken == time_limit
        return amount_released(open_valves, distances, time_limit, flow_rates), open_valves
    end

    released_closed_pairs = Iterators.map(closed_valves) do closed_valve
        new_open_valves = [open_valves; closed_valve]
        new_closed_valves = setdiff(closed_valves, [closed_valve])
        find_most_released_2(
                           new_open_valves, new_closed_valves, distances, flow_rates, time_limit; 
                           starting = starting
                          )
    end

    return argmax(first, released_closed_pairs)
end

function solve_2(file, timelimit = 26)
    GLOBAL_MAX[] = -1

    names, connected, flowrates = load_file(file)

    closed_valves = collect(names)
    filter!(closed_valves) do closed_valve
        flowrate = flowrates[closed_valve]
        flowrate > 0
    end
    distances = get_distances(connected)
    T = eltype(closed_valves)
    # ar = x -> amount_released(x, distances, timelimit, flowrates)
    most_released = find_most_released_3([T[], T[]], closed_valves, distances, flowrates, timelimit)
    
    println("For $file, the most released pressure with an elephant is $most_released.")
end

const GLOBAL_MAX = Ref(-1)

function find_most_released_3(
        open_valves_list, 
        closed_valves, 
        distances, 
        flow_rates, 
        time_limit; 
        starting = "AA"
    )

    if !allunique(Iterators.flatten(open_valves_list))
        error("Open valves' list, $open_valves_list, are not all unique, you tried to open a valve twice!")
    end

    times_taken = total_time_opening.(open_valves_list, Ref(distances), Ref(starting))
    # check if time has ran out
    for i in 1:length(open_valves_list)
        times_taken[i] < time_limit && continue
        # not_i = setdiff(1:length(open_valves_list), i)
        # length(not_i) == length(1:length(open_valves_list)) && error("Faild to set diff.")
        error("time should not be passed or met!")
    end

    cv_sort_perm = sortperm(closed_valves, by = cv -> flow_rates[cv], rev = true)
    theoretical_steps = 0

    theoretical_max = sum(open_valves_list, init = 0) do open_valves
        amount_released(open_valves, distances, time_limit, flow_rates)
    end + sum(Iterators.partition(cv_sort_perm, length(open_valves_list)), init = 0) do part
        cvs = closed_valves[part]
        theoretical_steps += 1
        sum(cvs) do cv
            max((time_limit - minimum(times_taken) - 2*theoretical_steps) * flow_rates[cv], 0)
        end
    end
    # sum(closed_valves, init = 0) do cv
    #     max((time_limit - minimum(times_taken) - 2) * flow_rates[cv], 0)
    # end

    if theoretical_max < GLOBAL_MAX[]
        # println("HIT global max, $(GLOBAL_MAX[]), with $theoretical_max.")
        return 0
    end

    # check if there are no more closed valves
    max_value = maximum(1:length(open_valves_list)) do open_valve_en_grata_i

        # min_time_taken, open_valve_en_grata_i = findmin(times_taken)
        min_time_taken = times_taken[open_valve_en_grata_i]

        grata_closed_valves = filter(closed_valves) do closed_valve
            grata_row = open_valves_list[open_valve_en_grata_i]
            open_valve = isempty(grata_row) ? starting : grata_row[end]
            return min_time_taken + distances[(closed_valve, open_valve)] + 1 < time_limit
        end |> collect

        if isempty(grata_closed_valves)
            return sum(open_valves_list) do open_valves
                amount_released(open_valves, distances, time_limit, flow_rates)
            end
        end

        # recurse in the possibilites
        maximum(grata_closed_valves) do closed_valve
            new_closed_valves = setdiff(grata_closed_valves, [closed_valve])
            new_open_valve_list = map(1:length(open_valves_list)) do i 
                if i == open_valve_en_grata_i
                    [open_valves_list[i]; closed_valve]
                else
                    open_valves_list[i]
                end
            end

            find_most_released_3(new_open_valve_list, new_closed_valves, distances, 
                                 flow_rates, time_limit; starting = starting)
        end
    end

    if max_value > 2459 && max_value > GLOBAL_MAX[]
        println("Surpassed current best of with $max_value.")
    elseif max_value > GLOBAL_MAX[]
        println("Surpassed the global best of with $max_value.")
    end
    GLOBAL_MAX[] = max(max_value, GLOBAL_MAX[])
    return max_value
end

# solve_2("test.txt")
solve_2("input.txt")
