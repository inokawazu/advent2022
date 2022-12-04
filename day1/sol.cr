def calculate_max_elf_calories(filename)
  raw_elf_list = File.read(filename)

  # puts elf_list.split("\n\n")
  elf_list = raw_elf_list.split("\n\n")
  
  max_cal = 0
  elf_list.each() do |elf|
    elf_cal = 0
    elf.each_line() do |cal|
      elf_cal += Int32.new(cal)
    end

    max_cal = Math.max(max_cal, elf_cal)
  end

  puts "The maximum number of calories held is #{max_cal} (for #{filename})"
end

# calculate_max_elf_calories "test.txt"
# calculate_max_elf_calories "input.txt"

def get_elf_calories(filename, n)
  raw_elf_list = File.read(filename)

  elf_list = raw_elf_list.split("\n\n")
  
  elf_cals = elf_list.map { |elf|
    elf_cal : Int32 = 0
    elf.each_line() do |cal|
      elf_cal += Int32.new(cal)
    end
    elf_cal
  }

  elf_cals.sort!
  elf_cals.reverse!
  puts "The top #{n} calories are #{elf_cals[0..n-1]} (for #{filename})"
  puts "Sum total is #{elf_cals[0..n-1].sum}"
end

get_elf_calories "test.txt", 3
get_elf_calories "input.txt", 3
