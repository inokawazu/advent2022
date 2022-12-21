const ORE_NAMES = (:ore, :clay, :obsidian, :geode)

get_ores(x) = getproperty.(Ref(x), ORE_NAMES)

struct Blueprint
    id
    ore
    clay
    obsidian
    geode
end

struct Ores
    ore
    clay
    obsidian
    geode
end

Ores() = Ores(0,0,0,0)

struct Robots
    ore
    clay
    obsidian
    geode
end

function mine(robots::Robots, ores::Ores)
    Ores((get_ores(robots) .+ get_ores(ores))...)
end

function canbuild(blueprint::Blueprint, ores::Ores, to_build::Symbol)
    cost = getproperty(blueprint, to_build)
    return all(get_ores(cost) .<= get_ores(ores))
end

function build(blueprint::Blueprint, robots::Robots, ores::Ores, to_build::Symbol)
    to_build in ORE_NAMES || error("ROBOT BUILD ERROR: $to_build is not a valid ore.")

    cost = getproperty(blueprint, to_build)

    all(get_ores(cost) .<= get_ores(ores)) || error("ROBOT BULID ERROR: \
                                                    not enough money to build a $to_build.")
    
    Robots((get_ores(robots) .+ (to_build == ore for ore in ORE_NAMES))...),
    Ores((get_ores(ores) .- get_ores(cost))...)
end

function load_file(file)
    map(readlines(file)) do line
        T = Int
        z = zero(T)

        line_nums = parse.(T, (
             match(r"Blueprint (\d+):", line)[1],
             match(r"Each ore robot costs (\d+) ore.", line)[1],
             match(r"Each clay robot costs (\d+) ore.", line)[1],
             match(r"Each obsidian robot costs (\d+) ore and (\d+) clay.", line)[1],
             match(r"Each obsidian robot costs (\d+) ore and (\d+) clay.", line)[2],
             match(r"Each geode robot costs (\d+) ore and (\d+) obsidian.", line)[1],
             match(r"Each geode robot costs (\d+) ore and (\d+) obsidian.", line)[2],
        ))
        
        Blueprint(
         line_nums[1],
         (ore = line_nums[2], clay = z,            obsidian = z, geode = z),
         (ore = line_nums[3], clay = z,            obsidian = z, geode = z),
         (ore = line_nums[4], clay = line_nums[5], obsidian = z, geode = z),
         (ore = line_nums[6], clay = z,            obsidian = line_nums[7], geode = z),
        )
    end
end

struct Node
    time::Int
    robots::Robots
    ores::Ores
    blueprint::Ref{Blueprint}
end

Node(blueprint::Blueprint) = Node(0, Robots(1,0,0,0), Ores(), Ref(blueprint))

const OR = Union{Ores, Robots}
Base.show(io::IO, bor::OR) = print(io, nameof(typeof(bor)), "(", join(get_ores(bor), ", "), ")")

Base.show(io::IO, b::Blueprint) = print(io, "Blueprint(", b.id, ")")

Base.show(io::IO, n::Node) = print(io, 
                                   "Node: ", 
                                   "Blueprint(id = $(n.blueprint[].id)), ", 
                                   "time: $(n.time), ",
                                   n.robots, ", ",
                                   n.ores
                                  ) 

function children(node::Node)
    child_time = node.time + 1

    (; robots, ores, blueprint) = node

    function build_then_mine(to_build)
        build_robots, build_ores = build(blueprint[], robots, ores, to_build)
        build_robots, mine(robots, build_ores)
    end
    build_mine_node(to_build) = Node(child_time, build_then_mine(to_build)..., blueprint) 

    build_iter = (build_mine_node(ore_name)
                  for ore_name in Iterators.reverse(ORE_NAMES)
                  if canbuild(blueprint[], ores, ore_name))

    do_nothing_iter = (Node(child_time, robots, mine(robots, ores), blueprint),)
   
    Iterators.flatten((
                       build_iter,
                       do_nothing_iter,
                      ))
end

function test_1(file, timelimit = 26)
    blueprints = load_file(file)

    robots = Robots(1,0,0,0)
    ores = Ores()
    
    for m in 1:timelimit
        for robot_name in Iterators.reverse(ORE_NAMES)
            canbuild(blueprints[1], ores, robot_name) || continue

            @info "Built $robot_name at $m minutes."
            robots, ores = build(blueprints[1], robots, ores, robot_name)
        end

        # @info "Mined $(join(get_ores(robots), ", "))"
        ores = mine(robots, ores)
    end

    @show ores
    @show robots
end

function test_2(file, timelimit = 10)
    blueprints = load_file(file)

    most_geodes = map(blueprints) do ith_bp
        @show ith_bp

        nodes = [Node(ith_bp)]
        seen = Dict{eltype(nodes), Int}()
        most_geode = -1
        i = 0
        while i < Inf && !isempty(nodes)
            i += 1

            node = pop!(nodes)
            # @info node
            # node in keys(seen) && @info seen[node]

            (; time) = node
            if time == timelimit 
                seen[node] = node.ores.geode # < most_geode ? typemin(typeof(node.ores.geode)) : node.ores.geode 
                if seen[node] > most_geode
                    @info "Found new record: $(seen[node])"
                end
                most_geode = max(node.ores.geode, most_geode)
                continue
            elseif node in keys(seen)
                continue
            end

            maximum_possible = let grobots = node.robots.geode, 
                gores = node.ores.geode, 
                n = timelimit - time,
                m = n - !canbuild(node.blueprint[], node.ores, :geode) 
                gores + grobots*length(1:n) + sum(1:m, init = 0)
            end
            if maximum_possible < most_geode
                seen[node] = typemin(Int)
                # @info "FOUND IMPOSSIBLE ROUTE, $i"
                continue
            end

            node_children = children(node)

            all_children_calculated = all(node_children) do node_child
                node_child in keys(seen)
            end

            if all_children_calculated
                # @info "ALL CHILDREN SEEN"
                seen[node] = maximum(nc -> seen[nc], node_children)
                continue
            end

            push!(nodes, node)
            for node_child in node_children
                if node_child in keys(seen)
                    # @info "Branch Cut"
                    continue
                end
                push!(nodes, node_child)
            end
        end

        most_geode
    end

    # foreach(println, seen)
    # @info "Iterations = $i."
    @info "Max Geode = $most_geodes."
    # return i
end

test_2("test.txt", 24)
# println([test_2("test.txt", i) for i in 1:10])
