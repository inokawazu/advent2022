struct Crate{C}
    contents::C
end

struct Move{I <: Integer}
    amount::I
    from::I
    to::I
end

function parse_file(file)
    lines = readlines(file)
    
    empty_line = findfirst(isempty∘strip, lines)
    
    initial_crate_lines, move_lines = lines[1:empty_line-1], lines[empty_line+1:end]
    
    moves = reverse(parse_move.(move_lines))

    stacks = parse_initial_cranes(initial_crate_lines)

    return stacks, moves
end

function parse_initial_cranes(crane_lines)
    crane_matrix = reduce(vcat, permutedims.(collect.(crane_lines)))
    crate_cols = findall(isnumeric, crane_matrix[end, :])

    stacks = [Crate{eltype(crane_matrix)}[] for _ in crate_cols]
    
    foreach(Iterators.drop(Iterators.reverse(eachrow(crane_matrix)), 1)) do row
        for (stack_i, col) in enumerate(crate_cols)
            element = row[col]
            isspace(element) && continue

            push!(stacks[stack_i], Crate(element))
        end
    end

    return stacks
end

function parse_move(str)
    sstr = strip(str)
    # amount_str, rest = split(parse_move, "move")
    csstr = replace(sstr, "move" => ",", "from" => ",", "to" => ",")
    scssstr = split(csstr, ",", keepempty = false)
    Move((parse.(Int, scssstr))...)
end

function execute!(stacks::AbstractVector, move::Move)
    for _ in 1:move.amount
        crate = pop!(stacks[move.from])
        push!(stacks[move.to], crate)
        # @info "Moved $crate from $(move.from) to  $(move.to)"
    end
end

function Base.show(io::IO, crate::Crate)
    print(io, "[", crate.contents, "]")
end

contents(c::Crate) = c.contents

let (stacks, moves) = parse_file("input.txt")
    while !isempty(moves)
        move = pop!(moves)
        execute!(stacks, move)
    end

    final_word = join(
                      map(stacks) do stack
                          contents(stack[end])
                      end
                     )

    println("The final word is $final_word.")
end

###############################################33

function execute_stack!(stacks::AbstractVector, move::Move)
    moving_crates = Crate[]

    # @info stacks[move.from]
    for _ in 1:move.amount
        crate = pop!(stacks[move.from])
        push!(moving_crates, crate)
    end

    # @info "Moved $(moving_crates) from $(move.from) to  $(move.to)"
    append!(stacks[move.to], reverse(moving_crates))
    # @info stacks[move.to]
end

let (stacks, moves) = parse_file("input.txt")
    while !isempty(moves)
        move = pop!(moves)
        execute_stack!(stacks, move)
    end

    final_word = join(
                      map(stacks) do stack
                          contents(stack[end])
                      end
                     )

    println("The final word is $final_word.")
end
