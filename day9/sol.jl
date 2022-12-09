@enum Direction Up Down Left Right

struct Move
    direction::Direction
    steps::Int64
end

struct Position
    x::Int64
    y::Int64
end

struct State
    head::Position
    tail::Position
end

State() = State(Position(0,0), Position(0,0))

function istouching(s::State)
    hx, hy = s.head.x, s.head.y
    tx, ty = s.tail.x, s.tail.y

    abs(hx - tx) <= 1 && abs(hy - ty) <= 1
end

function step(state::State, move::Move)
    d = move.direction
    
    new_head = if d == Left
        Position(state.head.x-1, state.head.y)
    elseif d == Right
        Position(state.head.x+1, state.head.y)
    elseif d == Up
        Position(state.head.x, state.head.y+1)
    elseif d == Down
        Position(state.head.x, state.head.y-1)
    end

    state = State(new_head, state.tail)
    istouching(state) && return state, Move(move.direction, move.steps - 1)

    dx = state.head.x - state.tail.x
    dy = state.head.y - state.tail.y
    new_tail_x = state.tail.x + (dx == 0 ? 0 : dx ÷ abs(dx))
    new_tail_y = state.tail.y + (dy == 0 ? 0 : dy ÷ abs(dy))

    new_tail = Position(new_tail_x, new_tail_y)
    State(new_head, new_tail), Move(move.direction, move.steps - 1)
end

function do_move(state::T, move::Move) where {T}
    history = T[]
    while move.steps > 0
        state, move = step(state, move)
        push!(history, state)
    end
    return state, history
end

function Base.parse(_::Type{Direction}, ds::AbstractString) 
    if ds == "R"
        Right
    elseif ds == "L"
        Left
    elseif ds == "U"
        Up
    elseif ds == "D"
        Down
    else
        error("$ds is not a valid direction")
    end
end

function load_file(file)
    lines = strip.(readlines(file))

    map(lines) do line
        d, s = split(line)
        direction = parse(Direction, d)
        steps = parse(Int64, s)
        Move(direction, steps)
    end
end

function simulate_1(moves)
    state = State()
    history = [state]
    
    for move in moves 
        state, new_history = do_move(state, move)
        append!(history, new_history)
    end

    (length∘Set)(map(m -> m.tail, history))
end

let moves = load_file("input.txt")
    state = State()
    n_visited = simulate_1(moves)
    println("The number of tiles visited by the tail is $n_visited.")
end

###########################################

Position() = Position(0, 0)

struct Rope
    positions::Vector{Position}
end

Rope(n::Integer) = Rope([Position() for _ in 1:n+1])

Base.getindex(r::Rope, i::Integer) = r.positions[i]
Base.setindex!(r::Rope, p::Position, i::Integer) = setindex!(r.positions, p, i)
Base.length(r::Rope) = length(r.positions)
Base.lastindex(r::Rope) = length(r)
Base.show(io::IO, p::Position) = print(io, "P(", p.x, ",", p.y, ")")

Base.:-(p1::Position, p2::Position) = p1.x - p2.x, p1.y - p2.y

function drag_update!(r::Rope, node_number::Integer)
    nn = node_number

    head, tail = r[nn-1], r[nn]
    all(<=(1), abs.(head - tail)) && return
    
    dx = head.x - tail.x
    dy = head.y - tail.y

    new_tail_x = tail.x + (dx == 0 ? 0 : dx ÷ abs(dx))
    new_tail_y = tail.y + (dy == 0 ? 0 : dy ÷ abs(dy))

    r[nn] = Position(new_tail_x, new_tail_y)
end

function step(r::Rope, m::Move)
    new_rope = deepcopy(r)
    d = m.direction
    
    new_rope[1] = if d == Left
        Position(new_rope[1].x-1, new_rope[1].y)
    elseif d == Right
        Position(new_rope[1].x+1, new_rope[1].y)
    elseif d == Up
        Position(new_rope[1].x, new_rope[1].y+1)
    elseif d == Down
        Position(new_rope[1].x, new_rope[1].y-1)
    end
    
    for node_number in 2:length(r)
        drag_update!(new_rope, node_number)
    end
    
    return new_rope, Move(m.direction, m.steps - 1)
end


function simulate_2(moves, n = 9)
    rope = Rope(n)
    tail_history = [rope[end]]
    
    for move in moves 
        rope, new_history = do_move(rope, move)
        new_tail_history = map(m -> m[end], new_history)
        append!(tail_history, new_tail_history)
    end

    (length∘Set)(tail_history)
end

let moves = load_file("input.txt")
    r = Rope(9)

    n_visited = simulate_2(moves)
    println("The number of tiles visited by the tail is $n_visited.")
end
