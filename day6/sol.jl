load_file(file) = open(file, "r") do f
    strip(readline(f))
end

function groups_of_n(itr, n)
    l = length(itr)
    (itr[i:i+n-1] for i in 1:l-n+1)
end

function solve(file, distinct_bytes)
    msg = load_file(file)

    first_byte = findfirst(groups_of_n(msg, distinct_bytes)) do s
        allunique(s)
    end

    println("For file, $file, the number of bytes processed is $(first_byte + distinct_bytes - 1) \
            for $distinct_bytes distinct byets.")
end


solve("input.txt", 4)

solve("input.txt", 14)
