function load_file(file)
    Set(Iterators.map(readlines(file)) do line
            tuple(parse.(Int, split(line, ","))...)
    end)
end

const DIRECTIONS = (
                    (1,0,0),
                    (-1,0,0),
                    (0,1,0),
                    (0,-1,0),
                    (0,0,1),
                    (0,0,-1),
                   )

function sum_surface_area(cube_coords)
    sum(cube_coords) do cube_coord
        sum(DIRECTIONS) do direction
            !(cube_coord .+ direction in cube_coords)
        end
    end
end

function solve_1(file)
    cube_coords = load_file(file)
    total_surface_area = sum_surface_area(cube_coords)
    println("The total surface area of $file is $total_surface_area.")
end

solve_1("test.txt")
solve_1("input.txt")

##################################################

neighbors(coord) = (coord .+ direction for direction in DIRECTIONS)

function sum_surface_area_no_inside(cube_coords)
    outside_coords, _ = find_outside_coords(cube_coords)

    sum(cube_coords) do cube_coord
        sum(in(outside_coords), neighbors(cube_coord))
    end
end

function find_outside_coords(cube_coords)
    max_coord =  map(1:3) do i
        maximum(c -> c[i], cube_coords)
    end
    min_coord = map(1:3) do i
        minimum(c -> c[i], cube_coords)
    end


    empty_coords = setdiff(
                           Set(Iterators.product((UnitRange.(min_coord, max_coord))...)),
                           cube_coords
                          )

    outside_coords = setdiff(
                             Set(Iterators.product((UnitRange.(min_coord .- 1, max_coord .+ 1))...)), 
                             cube_coords, empty_coords
                            )

    visited_outside = empty(cube_coords)
    to_visit_outside = collect(copy(outside_coords))
    
    while !isempty(to_visit_outside)
        current_outside_coord = popfirst!(to_visit_outside)
        push!(visited_outside, current_outside_coord)

        for neighbor in neighbors(current_outside_coord)
            all(min_coord .<= neighbor .<= max_coord) || continue
            neighbor in empty_coords || continue
            neighbor in to_visit_outside && continue
            neighbor in visited_outside && continue

            push!(to_visit_outside, neighbor)
        end
    end

    return visited_outside, setdiff(empty_coords, visited_outside)
end

function solve_2(file)
    cube_coords = load_file(file)

    # outside_coords, bubble_coords = find_outside_coords(cube_coords)
#     @show intersect(cube_coords, outside_coords)
#     @show intersect(cube_coords, bubble_coords)
#     @show outside_coords
#     @show bubble_coords
#     @show (2,2,5) in bubble_coords

    # println(find_outside_coords(cube_coords))
    # foreach(println, find_bubbles(cube_coords))

    total_surface_area = sum_surface_area_no_inside(cube_coords)
    println("The total surface area without bubbles of $file is $total_surface_area.")
end

solve_2("test.txt")
solve_2("input.txt")
