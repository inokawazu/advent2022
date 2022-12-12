def load_file(file)
  lines = File.read_lines(file) 

  start  = {0, 0}
  finish = {0, 0}
  
  elevation_grid = lines.map_with_index do |line, row|
    line.chars.map_with_index do |char, col|
      elevation = char

      if char == 'S'
        start  = {row, col}
        elevation = 'a'
      elsif char == 'E'
        finish = {row, col}
        elevation = 'z'
      end
      
      elevation
    end
  end

  return elevation_grid, start, finish
end

# p! load_file "test.txt"

def get_neighbors_locations(current_loc, elevation_grid)
  h = elevation_grid.size
  w = elevation_grid[0].size

  y = current_loc[0]
  x = current_loc[1]
  
  candidates = [{y+1,x}, {y-1,x}, {y,x+1}, {y,x-1}]
  
  candidates.reject! do |p|
    p[0] < 0 || p[1] < 0 || p[0] >= h || p[1] >= w
  end

  current_elev = elevation_grid[y][x]
  candidates.reject! do |p| 
    elevation_diff = elevation_grid[p[0]][p[1]] - current_elev
    elevation_diff > 1
  end

  candidates
end

def solve_1(file)
  elevation_grid, start, finish = load_file file
  p! start, finish
  visited = Set(Tuple(Int32,Int32)).new
  journey_deque = Deque.new([{start, 0}])
  best_minimum_steps = minimum_steps = -1
  
  until journey_deque.empty?
    current_loc, current_steps = journey_deque.shift

    if visited.includes? current_loc
      next
    elsif current_steps < best_minimum_steps
      next
    else
      best_minimum_steps = Math.max(current_steps, best_minimum_steps)
      visited << current_loc
    end

    if current_loc == finish
      minimum_steps = current_steps
      break
    end

    neighbors = get_neighbors_locations current_loc, elevation_grid

    neighbors.each do |p|
      journey_deque.push({p, current_steps + 1}) unless visited.includes? p
    end
  end

  if minimum_steps < 0
    puts "No solution was found for #{file}."
    return 
  end

  puts "The minimum number of steps for #{file} is #{minimum_steps}."
end

def solve_1_try_2(file)
  elevation_grid, start, finish = load_file file
  p! start, finish
  journey_stack = Deque.new([start])
  options_stack = Deque(Array(typeof(start))).new
  options_stack = Deque.new([get_neighbors_locations(start, elevation_grid)])

  until journey_stack.last == finish
    if options_stack.empty?
      puts "No solution found!"
      return
    elsif options_stack.last.empty?
      journey_stack.pop
      options_stack.pop
      next
    end

    journey_stack.push(options_stack.last.pop)

    possible_neighbors = get_neighbors_locations(journey_stack.last, elevation_grid)
    possible_neighbors.reject! {|p| journey_stack.includes?(p)}

    options_stack.push(possible_neighbors)
  end
  
  puts "The minimum number of steps for #{file} is #{journey_stack.size - 1}."
end

def solve_1_try_3(file, optional_start = nil, verbose = true)
  elevation_grid, start, finish = load_file file

  start = optional_start unless optional_start.nil?

  planned_places_to_visit = Set(typeof(start)).new
  visited_places = Set(typeof(start)).new
  next_places = Deque.new [{start, 0}]

  until next_places.empty?

    # take the next place and steps to that place
    current_place, current_steps = next_places.shift

    if visited_places.includes? current_place
      raise "Visiting place again! #{current_place}"
    else
      visited_places << current_place
    end

    # if the current place is found exit with solution
    if current_place == finish || (current_place[0] == finish[0] && current_place[1] == finish[1])
      verbose && puts "The minimum number of steps for #{file} is #{current_steps}."
      return current_steps
    end
    
    # find the near by places that one can step to
    possible_next_places = get_neighbors_locations current_place, elevation_grid

    possible_next_places.reject! {|p| planned_places_to_visit.includes?(p)}
    possible_next_places.reject! {|p| visited_places.includes?(p)}

    possible_next_places.each do |p|
      planned_places_to_visit << p
      next_places << {p, current_steps + 1}
    end
  end

  verbose && puts "No solution was found."
  return nil
end

solve_1_try_3 "input.txt"

#############################################3

def find_elevation_points(elevation_grid, elevation)
  points = [] of Tuple(Int32, Int32)

  elevation_grid.each_with_index do |row, i|
    row.each_with_index do |elem, j|
      points << {i, j} if elem == elevation
    end
  end

  return points
end

def solve_2(file)
  elevation_grid, _, finish = load_file file

  starting_points = find_elevation_points(elevation_grid, 'a')
  
  shortest_distance = starting_points.map do |start|
    result = solve_1_try_3(file, optional_start = start, verbose = false)
    result.nil? ? Int32::MAX : result
  end.min

  puts "The shortest distance for #{file} is #{shortest_distance}."
end

solve_2 "input.txt"
