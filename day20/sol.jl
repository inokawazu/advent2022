const DECRYPTION_KEY = 811589153

load_file(file) = map(l->parse(Int, l), readlines(file))

struct EncryptedData{U}
    data::U
    ordering::U
end

Base.length(ed::EncryptedData) = length(ed.data)
Base.getindex(ed::EncryptedData, i::Integer) = ed.data[mod1(i, length(ed))]
Base.keys(ed::EncryptedData) = collect(1:length(ed))

Base.iterate(ed::EncryptedData) = iterate(ed.data)
Base.iterate(ed::EncryptedData, i::Integer) = iterate(ed.data, i)

function swap!(ed::EncryptedData, i::Integer, j::Integer)
    l = length(ed)
    mi, mj = mod1(i, l), mod1(j, l)

    ed.data[mi], ed.data[mj] = ed.data[mj], ed.data[mi]
    ed.ordering[mi], ed.ordering[mj] = ed.ordering[mj], ed.ordering[mi]

    return
end

function find_original(ed::EncryptedData, i::Integer)
    data_index = findfirst(==(i), ed.ordering)
    return ed.data[data_index], data_index
end

function mix!(ed::EncryptedData, mixing::Integer, mixing_index::Integer)
    mixing = mixing % (length(ed) - 1)

    while mixing != 0
        next_index = mixing_index + sign(mixing)

        swap!(ed, mixing_index, next_index)

        mixing_index = next_index
        mixing += -sign(mixing)
    end
end

function load_encrypt_data(file)
    data = load_file(file)
    ordering = collect(1:length(data))
    
    return EncryptedData(data, ordering)
end

function mix!(ed::EncryptedData)
    for i in 1:length(ed)
        mix_amount, mix_index = find_original(ed, i)
        mix!(ed, mix_amount, mix_index)
    end
end

function solve_1(file)
    ed = load_encrypt_data(file)

    mix!(ed)

    zeroth_index = findfirst(==(0), ed)

    sol_sum = sum(ed[i] for i in zeroth_index+1000:1000:zeroth_index+3000)
    println("The sum of the three numbers for $file is $sol_sum.")
end

solve_1("input.txt")

################################################################

apply_key(ed::EncryptedData, key) =  @. ed.data = ed.data * key

function solve_2(file, iterations = 10)
    ed = load_encrypt_data(file)
    apply_key(ed, DECRYPTION_KEY)

    for _ in 1:iterations
        mix!(ed)
    end

    zeroth_index = findfirst(==(0), ed)
    sol_sum = sum(ed[i] for i in zeroth_index+1000:1000:zeroth_index+3000)
    println("The sum of the three numbers for $file is $sol_sum.")

    return sol_sum
end

@show solve_2("test.txt") == 1623178306

solve_2("input.txt")
