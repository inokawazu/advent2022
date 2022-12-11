require "big"

class Monkey
  property items
  property test_int

  def initialize(
    starting_items : Array(BigInt),
    operation : String, 
    test_int : BigInt,
    true_monkey : BigInt,
    false_monkey : BigInt
  )
  
  @items = Deque(BigInt).new(starting_items)
  @operation = operation
  @test_int = test_int
  @true_monkey = true_monkey
  @false_monkey = false_monkey
  end

  def inspect_item(monkeys)
    inspecting = @items.shift
    
    op_ch = @operation.includes?('*') ? '*' : '+'

    operands = @operation.split(op_ch).map do |operand|
      # p! operand
      (operand.includes?("old") ? inspecting : BigInt.new(operand))
    end

    inspecting = op_ch == '*' ? operands.product : operands.sum

    inspecting //= 3
    
    if inspecting % @test_int == 0
      monkeys[@true_monkey].items.push(inspecting)
    else
      monkeys[@false_monkey].items.push(inspecting)
    end
  end

  def inspect_item_worried(monkeys)
    inspecting = @items.shift
    
    op_ch = @operation.includes?('*') ? '*' : '+'

    operands = @operation.split(op_ch).map do |operand|
      (operand.includes?("old") ? inspecting : BigInt.new(operand))
    end

    inspecting = op_ch == '*' ? operands.product : operands.sum

    mod_number = monkeys.map do |m|
      m.test_int
    end.product

    # p! inspecting

    inspecting = inspecting % mod_number

    if inspecting % @test_int == 0
      monkeys[@true_monkey].items.push(inspecting)
    else
      monkeys[@false_monkey].items.push(inspecting)
    end
  end
end

def load_file(file)
  lines = File.read_lines file

  monkeys = [] of Monkey

  monkey_number = 0
  
  until lines.empty?
    if lines[0].blank?
      lines.shift 
      next
    end
    
    monkey_lines = lines.shift(6)
    
    monkey_items = (monkey_lines[1]).strip.lchop("Starting items: ").split(',').map do |ns|
      BigInt.new(ns)
    end

    # monkey_lines[2] = 
    operation = monkey_lines[2].lchop("  Operation: new = ")
    test_int = BigInt.new(monkey_lines[3].lchop("  Test: divisible by "))
    true_monkey = BigInt.new(monkey_lines[4].lchop("    If true: throw to monkey"))
    false_monkey = BigInt.new(monkey_lines[5].lchop("    If false: throw to monkey"))
    
    monkeys.push Monkey.new(monkey_items, operation, test_int, true_monkey, false_monkey)
    
    monkey_number += 1
  end

  return monkeys
end

def solve_1(file)

  monkeys = load_file(file)

  activities = Array.new(monkeys.size, 0)

  round = 0
  while round < 20
    monkey_i = 0
    while monkey_i < monkeys.size
      monkey = monkeys[monkey_i]

      until monkey.items.empty?
        # p! monkey.items
        monkey.inspect_item monkeys
        # p! monkey.items
        # p! monkeys[3].items
        activities[monkey_i] += 1
      end

      monkey_i += 1
    end

    round += 1
  end

  sorted_activities = activities.sort
  sorted_activities.reverse!
  monkey_business = sorted_activities[0] * sorted_activities[1]

  puts "For file, #{file}, the monkey business is #{monkey_business}."
end

solve_1 "input.txt"

##############################################################333

def solve_2(file)

  monkeys = load_file(file)

  activities = Array.new(monkeys.size, BigInt.new(0))

  round = 0
  while round < 10000
    monkey_i = 0
    while monkey_i < monkeys.size
      monkey = monkeys[monkey_i]

      until monkey.items.empty?
        # p! monkey.items
        monkey.inspect_item_worried monkeys
        # p! monkey.items
        # p! monkeys[3].items
        activities[monkey_i] += 1
      end

      monkey_i += 1
    end

    round += 1
    # p! round
  end

  p! activities
  sorted_activities = activities.sort
  sorted_activities.reverse!
  monkey_business = sorted_activities[0] * sorted_activities[1]

  puts "For file, #{file}, the worried monkey business is #{monkey_business}."
end

solve_2 "input.txt"
