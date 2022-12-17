const LINE_TEMPLATE = "Valve VVV has flow rate=VVV; tunnel lead to valve VVV"
const LINE_SPLITS = split(LINE_TEMPLATE, "VVV", keepempty=false)

function load_file(file)::Vector{Valve}
    lines = readlines(file)

    return map(lines) do line
        name, flow_rate, connected = parse_line(line)
        return Valve(name, flow_rate, connected)
    end
end

mutable struct Valve{T<:Integer}
    name::String
    flow_rate::T
    connected_to::Vector{String}
    isopen::Bool
end

function Valve(
    name::String,
    flow_rate::T,
    connected_to::Vector{String}; status=false
) where {T<:Integer}
    return Valve(name, flow_rate, connected_to, status)
end

isopen(v::Valve) = v.isopen
flowrate(v::Valve) = v.flow_rate
name(v::Valve) = v.name
neighbors(v::Valve) = v.connected_to

function open!(v::Valve)
    isopen(v) && error("Cannot open the already open valve $(name(v)).")
    v.isopen = true
end

function Base.show(io::IO, v::Valve)
    print(io,
          v.name, "($(isopen(v) ? "Open" : "Closed")) : ",
        "flow rate = ", rpad(v.flow_rate, 2),
        "; connected to (", join(v.connected_to, ", "), ")")
end

function parse_line(line)
    org_line = line

    line = replace(line, "tunnels" => "tunnel", "valves" => "valve", "leads" => "lead")

    for split in LINE_SPLITS
        line = replace(line, split => "XXX")
    end

    fields = split(line, "XXX", keepempty=false)

    length(fields) == 3 || error("Found $(length(fields)) number of fields instead of \
                                 3 for \"$org_line\".")

    return string(fields[1]), parse(Int, fields[2]), string.(strip.(split(fields[3], ",")))
end

function solve_1(file, time_limit=30)
    valves = load_file(file)
    current_valve = valves[findfirst(v -> v.name == "AA", valves)]

    foreach(println, valves)

    minutes_passed = 0
    total_released = 0
    while minutes_passed < time_limit

        time_left = time_limit - minutes_passed

        action = get_next_action(current_valve, valves, time_left)
        println(action)

        current_valve = get_next_valve(action)
        update_valves!(valves, action)
        minutes_passed += get_time_taken(action)
        total_released += get_total_released(action)
    end

    foreach(println, valves)
    println("For $file the maximum able to be released is $total_released.")
end

abstract type Action end

get_next_valve(a::Action) = a.next_valve

struct DoNothing <: Action
    next_valve::Valve
end

Base.show(io::IO, _::DoNothing) = print(io, "Action: Did nothing.")

update_valves!(_::AbstractVector{Valve}, _::DoNothing) = return
get_time_taken(_::DoNothing) = 1
get_total_released(_::DoNothing) = 0

struct GoToAndOpen <: Action
    next_valve::Valve
    released_amount::Int
    minutes_passed::Int
end

Base.show(io::IO, gtao::GoToAndOpen) = print(io, 
                                             "Action: Went to ", name(gtao.next_valve), 
                                             " and opened it."
                                            )

function update_valves!(valves::AbstractVector{Valve}, gtoa::GoToAndOpen)
    next_valve_name = name(get_next_valve(gtoa))
    next_valve_ind = findfirst(v->name(v) == next_valve_name, valves)
    next_valve = valves[next_valve_ind]
    
    open!(next_valve)
end

get_time_taken(gtao::GoToAndOpen) = gtao.minutes_passed
get_total_released(gtao::GoToAndOpen) = gtao.released_amount

function get_next_action(
    current_valve::Valve,
    valves::AbstractVector{Valve},
    time_left::Integer
)

    closed_valve_indices = findall(!isopen, valves)

    if isempty(closed_valve_indices)
        return DoNothing(current_valve)
    end

    released_amounts, time_taken = 
        get_total_released_amounts_and_times_taken(current_valve, valves, time_left)
    # @show released_amounts[closed_valve_indices]

    next_valve_index = argmax(i -> released_amounts[i], closed_valve_indices)
    # @show next_valve_index

    next_valve = valves[next_valve_index]
    next_time_taken = time_taken[next_valve_index]
    # @show next_time_taken - 1

    best_released_amount = released_amounts[next_valve_index]

    return GoToAndOpen(next_valve, best_released_amount, next_time_taken)
end

function get_total_released_amounts_and_times_taken(
    current_valve::Valve,
    valves::AbstractVector{Valve},
    time_left::Integer
)

    steps_to_list = get_steps_to(current_valve, valves)
    
    released_amounts = map(steps_to_list, valves) do steps, valve
        (time_left - (steps + 1)) * flowrate(valve)
    end
    return  released_amounts, (steps_to_list .+ 1)
end

function get_steps_to(starting_valve::Valve, valves::AbstractVector)
    visited_names = Set{String}()

    queue = [(name(starting_valve), 0)]
    
    to_distances = fill(-1, length(valves))
    
    while !isempty(queue)
        current_valve_name, current_distance = popfirst!(queue)

        current_valve_name in visited_names && continue
        push!(visited_names, current_valve_name)

        current_valve_index = findfirst(valves) do valve
            name(valve) == current_valve_name
        end
        to_distances[current_valve_index] = current_distance

        foreach(neighbors(valves[current_valve_index])) do neighbor_name
            push!(queue, (neighbor_name, current_distance + 1))
        end
    end

    # @show to_distances
    if any(to_distances .< 0) 
        error("Could not find distances to all the valves from $starting_valve.")
    end

    return to_distances
end

solve_1("test.txt")

# let valves = load_file("test.txt")
#     foreach(println, valves)
#     println("===============================---")
#     valve = valves[2]
#     valve.isopen = true
#     foreach(println, valves)
# end
