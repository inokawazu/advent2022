load_file(file) = strip.(readlines(file))

struct Directory
    name
    contents
end

name(d::Directory) = d.name

size(d::Directory) = sum(size, d.contents, init = 0)

function printdir(d::Directory, level = 0)
    println("\t"^level, "Directory: ", d.name, "($(size(d)) bytes)")
    foreach(d.contents) do c
        printdir(c, level + 1)
    end
end

struct File 
    name
    size::Integer
end

printdir(f::File, level = 0) = println("\t"^level, "File: ", f.name, "(", f.size, " bytes)")

name(f::File) = f.name

size(f::File) = f.size

iscd(c) = startswith(c, raw"$ cd ")
isls(c) = startswith(c, raw"$ ls")

isthedir(content, dirname) = content isa Directory && name(content) == dirname
isthefile(content, filename) = content isa File && name(content) == filename

function cd!(dir_stack, cmd)
    dir = replace(cmd, raw"$ cd " => "")
    
    if dir == ".."
        return pop!(dir_stack)
    elseif dir == "/"
        return
    else
        push!(dir_stack, dir)
        return
    end
end

function get_ls_out!(cs) 
    out = []
    while !isempty(cs) && !startswith(first(cs), raw"$")
        o = popfirst!(cs)
        # println("Processed $o")
        push!(out, o)
    end
    return out
end

function update_dir_structure!(current_dir::Directory, dir_stack, ls_out)
    for s_dir in dir_stack
        diri = findfirst(c -> isthedir(c, s_dir), current_dir.contents)
        isnothing(diri) && error("Could not find dir $s_dir.")
        current_dir = current_dir.contents[diri]
    end

    for out in ls_out
        if startswith(out, "dir")
            _, dirname = split(out)
            any(c -> isthedir(c, dirname), current_dir.contents) && continue
            
            # println("adding directory $dirname")
            push!(current_dir.contents, Directory(dirname, []))
        elseif all(isnumeric, split(out)[1])
            size, filename = split(out)
            
            any(c -> isthefile(c, filename), current_dir.contents) && continue

            # println("adding file $filename")
            push!(current_dir.contents, File(filename, parse(Int, size)))
        else 
            error("Found ls out that is unclassified.")
        end
    end
end

function make_dir_structure(cmds)
    dir_stack = AbstractString[]

    dir_structure = Directory("root", [])

    cs = deepcopy(cmds)
    
    while !isempty(cs)
        c = popfirst!(cs)

        if iscd(c)
            cd!(dir_stack, c)
            # println("Current Directory: /", join(dir_stack, "/"))
        elseif isls(c)
            # println("LS")
            ls_out = get_ls_out!(cs)
            update_dir_structure!(dir_structure, dir_stack, ls_out)
        else
            error("Command NOT CLASSIFIED $c")
        end
    end

    return dir_structure
end

part_1_sum(_::File) = 0

function part_1_sum(d::Directory)
    toadd = size(d) <= 100000 ? size(d) : 0

    if toadd > 0 
        println("Adding $toadd, from dir $(d.name)")
    end

    return toadd + sum(part_1_sum, d.contents)
end

let dir_structure = make_dir_structure(load_file("input.txt") ) 
    println("The part 1 sum is $(part_1_sum(dir_structure)).")
end

################################

const AVAILABLE_BYTES = 70_000_000
const NEEDED_UNUSED = 30_000_000

directories(d::Directory) = (c for c in d.contents if c isa Directory)

function get_dir_size_dict(d::Directory)
    queue = collect(directories(d))
    size_dict = Dict{String, Int}(name(d) => size(d))
    overlap = 0
    
    while !isempty(queue)
        curr = popfirst!(queue)
        # haskey(size_dict, name(curr)) && error("Overlapping directory names found!")
        overlap_str = ""
        haskey(size_dict, name(curr)) && (overlap_str *= string((overlap += 1)))
        size_dict[name(curr) * overlap_str] = size(curr)

        foreach(directories(curr)) do x
            push!(queue, x)
        end
    end

    return size_dict
end

function part_2_smallest_delete_dir(d)
    dir_size = get_dir_size_dict(d)
    
    space_available = Dict(
                           map(keys(dir_size) |> collect) do name
                               size = dir_size[name]
                               name => AVAILABLE_BYTES - dir_size["root"] + size
                           end
                          )

    big_enough_names = filter(space_available) do pair
        _, available = pair
        NEEDED_UNUSED < available
    end |> keys

    minimum(big_enough_names) do name
        dir_size[name]
    end
end

let dir_structure = make_dir_structure(load_file("input.txt") ) 
    println("The part 2 sum is $(part_2_smallest_delete_dir(dir_structure)).")
end
