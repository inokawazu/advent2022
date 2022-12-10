def load_file(file)
  return File.read_lines(file)
end

def is_noop(line) : Bool
  return line.includes?("noop")
end

def parse_addx(line) : Int32
  return Int32.new(line[5..])
end

def solve_1(file)
  lines = Deque.new(load_file(file))

  special_cycles = Set{20, 60, 100, 140, 180, 220}
  signal_strength_sum = 0

  cycle = 1
  
  # add_deq = Deque(Int32).new
  add_reg = nil
  instruction_time = 0

  x_reg = 1

  until cycle >= 220 && lines.empty?
    if !lines.empty? && instruction_time < 1
      line = lines.shift
      unless is_noop(line)
        add_reg = parse_addx(line)
      end
    end

    if special_cycles.includes?(cycle)
      # p! cycle, x_reg, cycle * x_reg
      signal_strength_sum += cycle * x_reg
    end

    unless add_reg.nil?
      if instruction_time >= 1
        x_reg += add_reg
        add_reg = nil
      end
      instruction_time = (instruction_time + 1) % 2
    end

    cycle += 1
  end

  puts "The sum of the signal strengths for #{file} is #{signal_strength_sum}."
end

solve_1 "input.txt"

##############################################################

def print_screen(screen)
  screen.each do |line|
    puts line.join()
  end
end

def solve_2(file)
  lines = Deque.new(load_file(file))

  screen = [
    Array.new(40, '.'),
    Array.new(40, '.'),
    Array.new(40, '.'),
    Array.new(40, '.'),
    Array.new(40, '.'),
    Array.new(40, '.')
  ]

  print_screen screen

  special_cycles = Set{20, 60, 100, 140, 180, 220}
  signal_strength_sum = 0

  cycle = 1
  
  add_reg = nil
  instruction_time = 0

  x_reg = 1

  until cycle >= 240 && lines.empty?

    if cycle <= 21
      puts "Start of the Cycle #{cycle}"
      # p! x_reg
    end

    if !lines.empty? && instruction_time < 1
      line = lines.shift
      unless is_noop(line)
        add_reg = parse_addx(line)
      end
    end

    if cycle <= 21
      puts "During of the Cycle #{cycle}"
      # p! x_reg
    end

    if special_cycles.includes?(cycle)
      signal_strength_sum += cycle * x_reg
    end

    if ((cycle % 40 - 1) - (x_reg)).abs <= 1
      row = cycle // 40
      col = cycle % 40
      screen[row][col] = '#'
    end
    
    unless add_reg.nil?
      if instruction_time >= 1
        x_reg += add_reg
        add_reg = nil
      end
      instruction_time = (instruction_time + 1) % 2
    end

    if cycle <= 21
      puts "End of the Cycle #{cycle}"
      # p! x_reg
    end

    cycle += 1
  end

  puts
  print_screen screen
end

solve_2 "input.txt"
