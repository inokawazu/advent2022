function load_file(file)
    map, path = split(read(file, String), "\n\n")

    parse_map(map), parse_path(path)
end

function parse_map(map_str)
    rows = collect.(split(map_str, "\n"))
    ml = maximum(length, rows)
    filled_rows = Iterators.map(v -> [v; fill(' ', ml - length(v))], rows)

    return permutedims(reduce(hcat, filled_rows))
end

abstract type Instruction end

struct TurnRight <: Instruction end
struct TurnLeft <:Instruction end
struct MoveForward{I} <: Instruction
    spaces::I
end

function parse_path(path)
    pqueue = collect(strip(path))
    instructions = Instruction[]
    while !isempty(pqueue)
        c = popfirst!(pqueue)

        if isdigit(c)
            while !isempty(pqueue) && isdigit(pqueue[1])
                c *= popfirst!(pqueue)
            end
            push!(instructions, MoveForward(parse(Int, c)))
        elseif c == 'R'
            push!(instructions, TurnRight())
        elseif c == 'L'
            push!(instructions, TurnLeft())
        else
            error("Unregnized instruction char $c")
        end
    end
    return instructions
end

const DIRECTIONS = (
                    up    = (-1,  0),
                    left  = ( 0, -1),
                    down  = ( 1,  0),
                    right = ( 0,  1),
                   )

struct Position{T}
    location::Tuple{T, T}
    heading::T
end

execute(p::Position, _::TurnLeft , map) = Position(p.location, mod1(p.heading + 1, 4))
execute(p::Position, _::TurnRight, map) = Position(p.location, mod1(p.heading - 1, 4))

function execute(
        p::Position{T}, 
        mf::MoveForward{T}, 
        map::AbstractMatrix{<: AbstractChar}
    ) where T
    (; location, heading) = p
    moving = mf.spaces
    direction = DIRECTIONS[heading]
    map_size = size(map)

    while moving > 0
        next_location = @. mod1(location + direction, map_size)
        next_space = map[next_location...]

        if next_space == ' '
            while next_space == ' '
                next_location = @. mod1(next_location + direction, map_size)
                next_space = map[next_location...]
            end
        end 

        if next_space == '.'
            location = next_location
            moving -= 1
        elseif next_space == '#'
            moving = 0
        else
            error("Map space, $next_space, not recognizedx")
        end
    end

    return Position(location, heading)
end

Base.show(io::IO, p::Position) = print(
                                       io,
                                       "P(", 
                                       p.location, ", ", DIRECTIONS[p.heading]
                                       , ")")

score(p::Position) = 1000p.location[1] + 4p.location[2] + (3 + 1 - p.heading)

# foreach(println∘join, eachrow(load_file("test.txt")))
# foreach(println, load_file("test.txt")[2])

function solve_1(file; verbose = false)
    jungle_map, instructions = load_file(file)

    starting_location = reverse(Tuple(findfirst(==('.'), permutedims(jungle_map))))
    starting_heading  = 4
    
    starting_position = Position(starting_location, starting_heading)
    
    verbose && foreach(println∘join, eachrow(jungle_map))
    verbose && @info "The initial position is $starting_position \
    on a $(jungle_map[starting_location...])"

    do_in(p, i) = let jungle_map = jungle_map
        verbose && @info p, i 
        execute(p, i, jungle_map)
    end 

    last_position = foldl(do_in, instructions, init = starting_position)

    println("For $file, the last position is $last_position, with a score \
            of $(score(last_position)).")
end

# solve_1("input.txt")

#######################################################


# function identify_cubesides(
#         map::AbstractMatrix{<: AbstractChar}, side_size::Integer
#     )
#     window = (side_size-1)*one(CartesianIndex(size(map)))
#     # id = 0
#     inds = CartesianIndices(size(map))

#     sides = []

#     for I in first(inds):last(inds)-window
#         Iw = I:I+window
#         # @show Iw

#         all(s -> isempty(intersect(s, Iw)), sides) || continue
#         all(map[Iw] .!= ' ') || continue

#         push!(sides, Iw)
#     end

#     return sides
# end

joinprintln(x) = foreach(println∘join, x)

function identify_cubesides(
        map::AbstractMatrix{<: AbstractChar}, side_size::Integer
    )
    unitI = one(CartesianIndex(size(map)))
    window = (side_size-1)*unitI
    id = 0
    inds = CartesianIndices(size(map))

    sides = []

    for I in first(inds):side_size*unitI:last(inds)-window
        Iw = I:I+window

        all(s -> isempty(intersect(s, Iw)), sides) || continue
        if any(map[Iw] .== ' ')
            push!(sides, 0) 
            continue
        end

        id += 1
        push!(sides, id)
    end

    return identity.(reshape(sides, (size(map) .÷ side_size)))
end

let (jungle_map, _) = load_file("input.txt")
    cube_sides = identify_cubesides(jungle_map, 50)
    joinprintln(eachrow(cube_sides))
end
let (jungle_map, _) = load_file("test.txt")
    cube_sides = identify_cubesides(jungle_map, 4)
    joinprintln(eachrow(cube_sides))
end
