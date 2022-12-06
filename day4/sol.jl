parse_line(line) = split(strip(line), ",")

function parse_assignment(line) 
    left, right = split(strip(line), "-")
    return parse(Int, left):parse(Int, right)
end

function has_complete_overlay(assignments)
    issubset(assignments[1], assignments[2]) || issubset(assignments[2], assignments[1])
end

let lines = readlines("input.txt")
    cnt = count(lines) do line
        pline = parse_line(line)
        assignments = parse_assignment.(pline)
        has_complete_overlay(assignments)
    end

    println("The total number of complete overlaps is $cnt.")
end

####################################################################

function has_any_overlay(assignments)
    !isempty(intersect(assignments...))
end

let lines = readlines("input.txt")
    cnt = count(lines) do line
        pline = parse_line(line)
        assignments = parse_assignment.(pline)
        has_any_overlay(assignments)
    end

    println("The total number of partial overlaps is $cnt.")
end
