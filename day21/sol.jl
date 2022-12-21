function loadfile(file)
    Iterators.map(parseline, readlines(file))
end

function parseline(line)
    monkey_name, job_str = split(strip(line), ": ")

    job_parsed = if all(isdigit, job_str) 
        parse(Int, job_str)
    else
        arg1, op, arg2 = split(job_str)
        (x = string(arg1) , op = Symbol(op), y = string(arg2))
    end

    return string(monkey_name), job_parsed
end

function symbol_to_func(op::Symbol)
    if op == :+
        +
    elseif op == :-
        -
    elseif op == :/
        fld
    elseif op == :*
        *
    else
        error("Operation, $op, is not recognized.")
    end
end
# foreach(println, loadfile("test.txt"))

function solve_1(file; verbose = false)
    monkey_job_dict = Dict(loadfile(file)) # |> println
    
    monkey_results = Dict{String, Int}()
    
    monkey_stack = ["root"]
    
    max_stack_size = 0

    while !isempty(monkey_stack)
        max_stack_size = max(max_stack_size, length(monkey_stack))

        monkey = pop!(monkey_stack)

        monkey in keys(monkey_stack) && continue

        monkey_job = monkey_job_dict[monkey]

        if monkey_job isa Number
            verbose && @info "$monkey yells $monkey_job."
            monkey_results[monkey] = monkey_job
            continue
        end

        (; x, y, op) = monkey_job

        if !(x in keys(monkey_results)) || !(y in keys(monkey_results))
            push!(monkey_stack, monkey)
            !(x in keys(monkey_results)) && push!(monkey_stack, x)
            !(y in keys(monkey_results)) && push!(monkey_stack, y)
            verbose && @info "$monkey listens for $x and $y"
            continue
        end

        op_func = symbol_to_func(op)
        monkey_results[monkey] = op_func(monkey_results[x], monkey_results[y])

        verbose && @info "$monkey yells \
                          $(x)($(monkey_results[x])) $(op) $(y)($(monkey_results[y])) \
                          = $(monkey_results[monkey])"
    end

    verbose && @info "The stack grew to be $max_stack_size tall."
    println("The value of monkey, root, for $file, is $(monkey_results["root"])")
end

# solve_1("test.txt"; verbose = true)
solve_1("input.txt"; verbose = false)

#######################################################

abstract type Expression end

struct NumberExpr{T} <: Expression
    value::T
end

struct BinaryOperation{E1<:Expression, E2<:Expression} <: Expression
    op::Symbol
    x::E1
    y::E2
end

function BinaryOperation(
        op::Symbol,
        ne1::NumberExpr{T},
        ne2::NumberExpr{U}) where {T <: Integer, U <: Integer}
    resulting_value = symbol_to_func(op)(ne1.value, ne2.value)
    return NumberExpr(resulting_value)
end

Base.:+(x::Expression, y::Expression) = BinaryOperation(:+, x, y)
Base.:-(x::Expression, y::Expression) = BinaryOperation(:-, x, y)
Base.:*(x::Expression, y::Expression) = BinaryOperation(:*, x, y)
Base.fld(x::Expression, y::Expression) = BinaryOperation(:/, x, y)

function unwrap_human(bo::BinaryOperation, rhs::Integer)
    unwrap_human(bo.op, bo.x, bo.y, rhs)
end

# function unwrap_human(
#         bo::BinaryOperation{NumberExpr, BinaryOperation{<:Expression, <:Expression}},
#         rhs::Integer)
#     (; op, x, y) = bo
#     y, x, r = x.value, y, rhs
    
#     new_rhs = 
#     if op == :+
#         r - y
#     elseif op == :-
#         y - r
#     elseif op == :/
#         fld(y, r)
#     elseif op == :*
#         fld(r, y)
#     else
#         error("Operation, $op, is not recognized.")
#     end

#     return unwrap_human(x, new_rhs)
# end

# function unwrap_human(
#         bo::BinaryOperation{NumberExpr{<:Integer}, NumberExpr{Symbol}},
#         rhs::Integer)
#     (; op, x, y) = bo
#     y, _, r = x.value, y, rhs
    
#     if op == :+
#         r - y
#     elseif op == :-
#         y - r
#     elseif op == :/
#         fld(y, r)
#     elseif op == :*
#         fld(r, y)
#     else
#         error("Operation, $op, is not recognized.")
#     end
# end

# function unwrap_human(
#         bo::BinaryOperation{BinaryOperation{<:Expression, <:Expression}, NumberExpr},
#         rhs::Integer)
#     (; op, x, y) = bo
#     x, y, r = x, y.value, rhs
    
#     new_rhs = 
#     if op == :+
#         r - y
#     elseif op == :-
#         r + y
#     elseif op == :/
#         r * y
#     elseif op == :*
#         fld(r, y)
#     else
#         error("Operation, $op, is not recognized.")
#     end

#     return unwrap_human(x, new_rhs)
# end

# function unwrap_human(bo::BinaryOperation{NumberExpr{Symbol}, NumberExpr{<:Integer}},
#         rhs::Integer)
#     (; op, x, y) = bo
#     _, y, r = x, y.value, rhs

#     if op == :+
#         r - y
#     elseif op == :-
#         r + y
#     elseif op == :/
#         r * y
#     elseif op == :*
#         fld(r, y)
#     else
#         error("Operation, $op, is not recognized.")
#     end
# end

function solve_2(file; verbose = false)
    monkey_job_dict = Dict(loadfile(file)) # |> println
    monkey_results = Dict{String, Expression}()

    monkey_stack = ["root"]
    max_stack_size = 0

    while !isempty(monkey_stack)
        max_stack_size = max(max_stack_size, length(monkey_stack))

        monkey = pop!(monkey_stack)
        monkey in keys(monkey_stack) && continue

        if monkey == "humn"
            verbose && @info "YOU yell the answer soon!!!!!!!!!!!!!!!!"
            monkey_results[monkey] = NumberExpr(:humn)
            continue
        end

        monkey_job = monkey_job_dict[monkey]

        if monkey_job isa Number
            verbose && @info "$monkey yells $monkey_job."
            monkey_results[monkey] = NumberExpr(monkey_job)
            continue
        end

        (; x, y, op) = monkey_job

        if !(x in keys(monkey_results)) || !(y in keys(monkey_results))
            push!(monkey_stack, monkey)
            !(x in keys(monkey_results)) && push!(monkey_stack, x)
            !(y in keys(monkey_results)) && push!(monkey_stack, y)
            verbose && @info "$monkey listens for $x and $y"
            continue
        end

        op_func = symbol_to_func(op)
        monkey_results[monkey] = op_func(monkey_results[x], monkey_results[y])

        verbose && @info "$monkey yells \
                          $(x)($(monkey_results[x])) $(op) $(y)($(monkey_results[y])) \
                          = $(monkey_results[monkey])"
    end

    monkey_expr = monkey_results["root"]
    corrected_monkey_expr = BinaryOperation(:-, monkey_expr.x, monkey_expr.y)

    human_result = 0

    while corrected_monkey_expr isa BinaryOperation
        (; op, x, y) = corrected_monkey_expr

        nr_on_left = typeof(x) <: NumberExpr{<: Integer}
        nr, corrected_monkey_expr = nr_on_left ? (x, y) : (y, x)
        
        verbose && @info "$(nr_on_left ? nr : "x") $op $(!nr_on_left ? nr : "x") = $human_result"

        human_result = if op == :+
            human_result - nr.value
        elseif op == :-
            nr_on_left ? -human_result + nr.value : human_result + nr.value
        elseif op == :/
            (nr_on_left && nr.value % human_result != 0) && error("NOT DIVISABLE!")
            nr_on_left ? fld(nr.value, human_result) : human_result * nr.value
        elseif op == :*
            (nr_on_left && human_result % nr.value != 0) && error("NOT DIVISABLE!")
            fld(human_result, nr.value)
        else
            error("Operation, $op, is not recognized.")
        end
    end

    verbose && @info "The stack grew to be $max_stack_size tall."
    println("The value of human for $file, is $human_result.")
end

# solve_2("test.txt", verbose = true)
solve_2("input.txt", verbose = false)
