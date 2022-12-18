const TUNNEL_WIDTH = 7
const STARTING_VERT_SPACE = 3
const STARTING_LEFT_SPACE = 2
const FLOOR = 0
const LEFT_WALL = 0

function load_file(file)
    return map(parse_char, collect(strip(read(file, String))))
end

function parse_char(c)
    if c == '<'
        return (-1, 0)
    elseif c == '>'
        return (1, 0)
    end

    error("Encoutered invalid input character, '$c'")
end

function load_layouts()
   file_content = strip(read("shapes.txt", String))

   return map(split(file_content, "\n\n")) do layout_chars
       mapreduce(vcat,  split(layout_chars)) do row
           ([c == '#' for c in row])'
       end |> collect
   end
end

mutable struct Rock{T}
    layout::Matrix{Bool}
    position::Tuple{T,T}
end

function positions(r::Rock{T}) where T
    [ 
     T.(r.position) .+ T.((array_x, array_y))
     for array_y in 0:size(r.layout, 1)-1 for array_x in 0:size(r.layout, 2)-1
     if r.layout[end-array_y, array_x+1]
    ]
end

mutable struct Simulation{T <: Integer}
    state::Symbol
    fallen_rock_positions # ::Set{Tuple{T, T}}
    nrocks::T
    falling_rock::Union{Rock, Nothing}

    lay_out_iter
    pushes_iter
    max_height::T
    fallen_rock_position_set::Set{Tuple{T, T}}
end

function Simulation{T}(pushes) where T
    lay_out_iter = Iterators.cycle(load_layouts())
    pushes_iter = Iterators.cycle(pushes)

    return Simulation(:not_falling, 
                      Tuple{T, T}[], 
                      zero(T), 
                      nothing, lay_out_iter,
                     pushes_iter,
                     FLOOR,
                     Set{Tuple{T,T}}()
                    )
end

nrocks(s::Simulation) = s.nrocks
state(s::Simulation) = s.state
fallen_rock_positions(s::Simulation) = s.fallen_rock_positions

function rock_height(s::Simulation)
    max_height = maximum(last, 
            Iterators.takewhile(
                                p -> p[2] >= s.max_height, 
                                Iterators.reverse(s.fallen_rock_positions)
                               ), 
            init = s.max_height)

    s.max_height = max(s.max_height, max_height)

    return s.max_height
end

function simulate!(s::Simulation)
    if state(s) == :not_falling
        spawn_rock!(s)
        return
    elseif state(s) == :falling
        push_rock!(s)
        drop_rock!(s)
        return
    end
    error("Invalid State: $(state(s))")
end

function spawn_rock!(s::Simulation{T}) where T
    next_layout, s.lay_out_iter = Iterators.peel(s.lay_out_iter)

    s.state = :falling
    starting_position = T.((
             LEFT_WALL + 1 + STARTING_LEFT_SPACE,
             rock_height(s) + FLOOR + 1 + STARTING_VERT_SPACE
            ))
    s.falling_rock = Rock(next_layout, starting_position)
    return
end

function push_rock!(s::Simulation{T}) where T
    next_push, s.pushes_iter = Iterators.peel(s.pushes_iter)
    current_falling_rock::Rock = s.falling_rock
    candidate_positions = map(positions(current_falling_rock)) do position
        @. T(position) + T(next_push)
    end

    if !iscollision(candidate_positions, s)
        new_posistion = s.falling_rock.position .+ next_push
        s.falling_rock.position = new_posistion
        # if !(s.falling_rock.position == current_falling_rock.position)
        #     error("Could not set position.")
        # end
    end
    return
end

function drop_rock!(s::Simulation{T}, drop_push = (0, -one(T))) where T
    current_falling_rock::Rock = s.falling_rock

    candidate_positions = map(positions(current_falling_rock)) do position
        @. T(position) + T(drop_push)
    end

    if !iscollision(candidate_positions, s)
        new_posistion = s.falling_rock.position .+ drop_push
        s.falling_rock.position = new_posistion
    else # hits bottom
        foreach(positions(current_falling_rock)) do fallen_position
            push!(s.fallen_rock_positions, fallen_position)
            push!(s.fallen_rock_position_set, fallen_position)
        end
        s.falling_rock = nothing
        s.state = :not_falling
        s.nrocks += 1
    end
    return
end

function iscollision(
        positions::AbstractVecOrMat{Tuple{T, T}}, 
        s::Simulation
    )::Bool where T
    
    any(positions) do position
        x, y = position
        y <= FLOOR || 
            !(0 < x <= TUNNEL_WIDTH) || 
            position in s.fallen_rock_position_set
    end
end

function solve_1(file, max_nrocks = 2022, T = Int)
    pushes = load_file(file)

    # T = Int
    sim = Simulation{T}(pushes)

    while !(nrocks(sim) == max_nrocks && state(sim) == :not_falling)
        # previous_state = state(sim)
        @inline simulate!(sim)
        # if previous_state == :falling && state(sim) == :not_falling
        #     println("Percent done, $((nrocks(sim) / max_nrocks) * 100)")
        # end
    end

    println("The height of the tower will be $(rock_height(sim)) high for $file with \
            $max_nrocks rocks.")
end

solve_1("test.txt")
solve_1("input.txt")

#############################################

const ROCKS  = Int[]
const HEIGHTS = Int[]

function solve_2(file, max_nrocks = 1000000000000, T = Int)
    pushes = load_file(file)

    @show nrock_iter = 7 * length(load_layouts()) * length(pushes)
    sim = Simulation{T}(pushes)

    while !(nrocks(sim) == nrock_iter && state(sim) == :not_falling)
        previous_state = state(sim)
        @inline simulate!(sim)
        if previous_state == :falling && state(sim) == :not_falling
            push!(HEIGHTS, rock_height(sim))
            push!(ROCKS, nrocks(sim))
        end
    end

    height_diffs = diff(HEIGHTS)
    window_size = 2 # length(load_layouts()) * length(pushes)
    first_window = @view(height_diffs[1:window_size])
    
    repeat_index = findfirst(2:length(height_diffs)-window_size) do other_starting
        other_window = @view(height_diffs[other_starting:other_starting+window_size])
        all(
            f == o for (f, o) in zip(first_window, other_window)
           )
    end

    println("The repeat_index is $repeat_index for $file.")

    # while !(nrocks(sim) == nrock_iter && state(sim) == :not_falling)
    #     @inline simulate!(sim)
    # end

    # println("The height of the giant tower will be $(rock_height(sim)) high for $file with \
    #         $max_nrocks rocks.")
end

# solve_2(file, max_nrocks = 1000000000000, T = Int) = solve_1(file, max_nrocks, T)
solve_2("test.txt")
solve_2("input.txt")
