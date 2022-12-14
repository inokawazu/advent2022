@enum CaveSpace Air Rock Sand

Char(cs::CaveSpace) = cs == Air ? '.' : cs == Rock ? '#' : 'o'

function load_file(file; sand_y = 0, sand_x = 500, has_infinite_floor = false)
    lines = readlines(file)
    
    rock_verts = map(lines) do line
        coords = split(line, " ->" )
        map(coords) do xy
            x, y = split(xy, ",")
            parse(Int, x), parse(Int, y)
        end
    end

    return Cave(rock_verts, (sand_x, sand_y); has_infinite_floor = has_infinite_floor)
end

struct Cave{T <: Integer}
    sand_entry::Tuple{T, T}
    matrix::Matrix{CaveSpace}
    xlims::Tuple{T, T}
    ylims::Tuple{T, T}
end

function Cave(rock_verts, sand_entry; has_infinite_floor = false)
    sand_x, sand_y = sand_entry
    xlims = extrema(v->v[1], Iterators.flatten(rock_verts), init = (sand_x, sand_x))
    ylims = extrema(v->v[2], Iterators.flatten(rock_verts), init = (sand_y, sand_y))

    if has_infinite_floor
        ylims = ylims .+ (0, 2)
        y_diff = ylims[2] - ylims[1] + 1
        xlims = (
                 min(sand_x - y_diff, xlims[1] - 2),
                 max(sand_x + y_diff, xlims[2] + 2)
                )
        floor_verts = [
                       [(xlims[1], ylims[2]), (xlims[2], ylims[2])]
                      ]
        rock_verts = [rock_verts; floor_verts]
    end

    cave_matrix = fill(Air, -(-(xlims...))+1, -(-(ylims...))+1)
    
    cave = Cave(sand_entry, cave_matrix, xlims, ylims)
    
    foreach(vs -> fillverts!(cave, vs, Rock), rock_verts)

    cave
end

function Base.show(io::IO, c::Cave) 
    println(io, "Cave: ")
    foreach(c.ylims[1]:c.ylims[2]) do y
        crow = map(c.xlims[1]:c.xlims[2]) do x
            ((x, y) == c.sand_entry && c[x,y] == Air) && return '+'
            Char(c[x, y]) 
        end
        println(io, join(crow, ""))
    end
end

function inbounds(c::Cave{T}, x::T, y::T) where T
    return c.xlims[1] <= x <= c.xlims[2] && c.ylims[1] <= y <= c.ylims[2]
end

function Base.getindex(c::Cave{T}, x::T, y::T) where T
    array_x = 1 + x - c.xlims[1]
    array_y = 1 + y - c.ylims[1]
    if !inbounds(c, x, y)
        return Air
    end
    return c.matrix[array_x, array_y]
end

function Base.setindex!(c::Cave{T}, cs::CaveSpace, x::T, y::T) where T
    array_x = 1 + x - c.xlims[1]
    array_y = 1 + y - c.ylims[1]
    return c.matrix[array_x, array_y] = cs
end

function fillverts!(cave::Cave, verts::AbstractVector, filler::CaveSpace)
    foreach(verts[1:end], verts[2:end]) do vn, vnp1
        foreach(verts_between_inclusive(vn, vnp1)) do vert
            cave[vert...] = filler
        end
    end
end

nsand(c::Cave) = count(==(Sand), c.matrix)

function gravity!(c::Cave{T}, sand_pos::Tuple{T,T}) where T
    c[sand_pos...] == Sand || error("Sand position must be Sand, \
                                    found $(c[sand_pos...]) at $sand_pos.")

    dirs = (sand_pos .+ (0,1), sand_pos .+ (-1,1), sand_pos .+ (1,1))
    
    if all(d->c[d...] != Air, dirs)
        return sand_pos
    end

    c[sand_pos...] = Air
    for dir in dirs
        if !inbounds(c, dir...)
            return (dir[1], Inf)
        elseif c[dir...] == Air
            c[dir...] = Sand
            return dir
        end
    end

    error("Unreachable")
end

function drop_sand(c_in::Cave)
    c = Cave(c_in.sand_entry, copy(c_in.matrix), c_in.xlims, c_in.ylims)
    c[(c.sand_entry)...] != Air && return c
    c[c.sand_entry...] = Sand
    sand_pos = c.sand_entry
    
    local next_sand_pos
    while sand_pos != (next_sand_pos = gravity!(c, sand_pos))
        if isinf(next_sand_pos[2])
            println("into the abyss!")
            break
        end
        sand_pos = next_sand_pos
    end

    return c
end

function verts_between_inclusive(v::Tuple{T,T}, w::Tuple{T,T}) where T <: Integer
    if v[1] == w[1] # same x
        x = v[1]
        ymin, ymax = min(v[2], w[2]), max(v[2], w[2])
        return [(x, y) for y in ymin:ymax]
    elseif v[2] == w[2] # same y
        y = v[2]
        xmin, xmax = min(v[1], w[1]), max(v[1], w[1])
        return [(x, y) for x in xmin:xmax]
    else
        error("Only can find vertices between vert on the same row or column, not for $v \
              and $w.")
    end
end

function simulate_until_same(cave::Cave)
    local next_cave
    while cave.matrix != (next_cave = drop_sand(cave)).matrix
        cave = next_cave
    end
    cave
end

function solve(file; has_infinite_floor = false, verbose = false)
    cave = load_file(file, has_infinite_floor = has_infinite_floor)

    verbose && println(cave)
    filled_cave = simulate_until_same(cave)
    verbose && println(filled_cave)

    number_of_sands = nsand(filled_cave)
    println("The number of at rest sands for $file is $number_of_sands.")
end

solve("input.txt")

##############################################################

solve("input.txt"; has_infinite_floor = true)
