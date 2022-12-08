load_file(file) = parse.(Int, permutedims(reduce(hcat, collect.(strip.(readlines(file))))))


function get_neighbor_heights(array, row, col)
    h, w = size(array)
    up = view(array, 1:row-1, col)
    down = view(array, row+1:h, col)
    left = view(array, row, 1:col-1)
    right = view(array, row, col+1:w)
    return reverse(up), down, reverse(left), right
end

function isvisible(grid, row, col)
    elem = grid[row, col]
    any(get_neighbor_heights(grid, row, col)) do direction
        return isempty(direction) || all(<(elem), direction)
    end
end

function count_visible(grid)
    return count(isvisible(grid, row, col) for row in 1:size(grid,1), col in 1:size(grid,2))
end

let grid = load_file("input.txt")
    number_visible = count_visible(grid)
    println("The number of visible trees is $number_visible.")
end

######################################################

function tree_score(grid, row, col)
    if row == 1 || col == 1 || row == size(grid, 1) || col == size(grid, 2)
        return zero(eltype(grid))
    end

    elem = grid[row, col]

    prod(get_neighbor_heights(grid, row, col)) do direction
        first_tree = findfirst(>=(elem), direction)
        return isnothing(first_tree) ? length(direction) : first_tree
    end
end

function find_best_tree_score(grid)
    return maximum(tree_score(grid, row, col) for row in 1:size(grid,1), col in 1:size(grid,2))
end

let grid = load_file("input.txt")
    number_visible = find_best_tree_score(grid)
    println("The best tree score is is $number_visible.")
end

