const VERBOSE = false

load_file(file) = readlines(file)

iscd(cmd) = startswith(cmd, raw"$ cd")
isls(cmd) = startswith(cmd, raw"$ ls")

function islsout(cmd)
    length(split(strip(cmd))) == 2 || return false

    return !startswith(cmd, raw"$")
end

function docd!(cmd, dir, dir_sizes)
    _, _, target = split(strip(cmd), " ")
    
    if target == ".." 
        return pop!(dir)
    end

    push!(dir, target)
    dir_sizes[target] = 0
    return
end

function take_ls_outputs!(cmds)
    output = []

    while !isempty(cmds) && islsout(first(cmds))
        push!(output, popfirst!(cmds))
    end

    return output
end

function update_filesizes_ls!(ls_outs, dir, dir_sizes)
    total_bytes = sum(ls_outs, init = 0) do out
        ssize, _... = split(strip(out))

        all(isnumeric, ssize) || return 0

        parse(Int, ssize)
    end

    dir_sizes[last(dir)] += total_bytes
end

function update_filesizes_popped!(popped_dir, dir, dir_sizes)
    parent_dir = isempty(dir) ? "/" : last(dir)
    dir_sizes[parent_dir] += dir_sizes[popped_dir]
end

function process_cmds(cmds)
    wcmds = copy(cmds)

    dir = String[]
    dir_sizes = Dict{String, Int}("/" => 0)
    
    while !isempty(wcmds)
        cmd = popfirst!(wcmds)

        popped_dir = nothing

        if iscd(cmd)
            popped_dir = docd!(cmd, dir, dir_sizes)
            VERBOSE && println("Dir: ", join(dir, "/"))
        elseif isls(cmd)
            VERBOSE && println("ls")
            ls_outs = take_ls_outputs!(wcmds)
            VERBOSE && foreach(println, ls_outs)
            update_filesizes_ls!(ls_outs, dir, dir_sizes)
        end

        isnothing(popped_dir) || update_filesizes_popped!(popped_dir, dir, dir_sizes)
    end

    while !isempty(dir)
        popped_dir = pop!(dir)
        update_filesizes_popped!(popped_dir, dir, dir_sizes)
    end
    
    return dir_sizes
end

let cmds = load_file("input.txt")
    VERBOSE && println(cmds)
    dir_sizes = process_cmds(cmds)

    total_size = 0
    for (dir, size) in dir_sizes
        dir == "/" && continue
        size > 100000 && continue

        total_size += size
    end

    println("The total number of byter from folders <100000 bytes is $total_size.")
end
