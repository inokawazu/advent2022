@enum Move Rock Paper Scissors
@enum Outcome Win Loss Draw

# points(m::Loss) = 0
# points(m::Draw) = 3
# points(m::Win) = 6
function points(o::Outcome)
    if o == Loss
        0
    elseif o == Draw
        3
    elseif o == Win
        6
    end
end

function match(opp::Move, you::Move)
    opp == you && return Draw

    if opp == Rock
        return you == Scissors ? Loss : Win
    elseif opp == Paper
        return you == Rock ? Loss : Win
    else # is Scissors
        return you == Paper ? Loss : Win
    end
end

# points(m::Rock) = 1
# points(m::Paper) = 1
# points(m::Scissors) = 1
function points(m::Move)
    if m == Rock 
        1
    elseif m == Paper
        2
    elseif m == Scissors
        3
    end
end

function parse_move(move::AbstractString)
    if move == "A" || move == "X"
        return Rock
    elseif move == "B" || move == "Y"
        return Paper
    elseif move == "C" || move == "Z"
        return Scissors
    else
        throw(ErrorException("$move is not a valid ABC or XYZ move."))
    end
end

function parse_match(line::String)
    str_moves = split(strip(line), " ")
    parse_move.(str_moves)
end

function sol1(file; verbose = false)
    lines = readlines(file)
    ttl_points = sum(lines) do line
        opp, you = parse_match(line)
        outcome = match(opp, you)
        verbose && println("You play $you vs $opp and $(outcome)")
        points(outcome) + points(you)
    end

    println("You earned $ttl_points points.")
end

sol1("input.txt")

##################################

function parse_outcome(outcome::AbstractString)
    if outcome == "X"
        return Loss
    elseif outcome == "Y"
        return Draw
    elseif outcome == "Z"
        return Win
    else
        throw(ErrorException("$outcome is not a valid XYZ outcome."))
    end
end

function parse_match2(line::String)
    opp_str, you_str = split(strip(line), " ")

    opp = parse_move(opp_str)
    outcome = parse_outcome(you_str)
    return opp, outcome
end

function infer_move(opp::Move, out::Outcome)
    out == Draw && return opp

    if opp == Rock
        out == Loss ? Scissors : Paper 
    elseif opp == Paper
        out == Loss ? Rock : Scissors 
    elseif opp == Scissors
        out == Loss ? Paper : Rock
    end
end



function sol2(file; verbose = false)
    lines = readlines(file)
    total = sum(lines) do line
        opp, out = parse_match2(line)
        you = infer_move(opp, out)
        verbose && println("Your opponent will choose $opp and you want to $out, choose $you.")
        points(you) + points(out)
    end
    println("You earned $total points.")
end

sol2("input.txt")
