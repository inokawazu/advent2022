function load_file(file)
    lines = readlines(file)

    beacons = Vector{Tuple{Int, Int}}()
    sensors = Vector{Tuple{Int, Int}}()
    
    foreach(lines) do line
        
        rep_str = replace(
                          line, 
                          "Sensor at x=" => ",", 
                          ", y=" => ",", 
                          ": closest beacon is at x=" => ","
                         )
        
        sx, sy, bx, by = parse.(Int, split(rep_str, ",")[2:5])

        push!(beacons, (bx, by))
        push!(sensors, (sx, sy))
    end

    return sensors, beacons
end

function solve_1(file, yrow::Integer)
    sensors, beacons = load_file(file)

    sbeacons = Set(beacons)
    ssensors = Set(sensors)

    no_becons = mapreduce(union, sensors, beacons) do sensor, beacon
        get_no_beacons_locations(sensor, beacon, sbeacons, ssensors, yrow)
    end
    no_becons_count = length(no_becons)
    
    println("For $file at y-row, $yrow, number of no beacon positions is $no_becons_count.")
end

manhattan_distance(x, y) = sum(@. abs(x - y))

function get_no_beacons_locations(sensor, beacon, beacons, sensors, yrow)
    d = distance = manhattan_distance(sensor, beacon)

    if !(yrow in sensor[2]-d:sensor[2]+d)
        return Set{typeof(beacon)}()
    end
    
    Set(
        (x, yrow) for x in sensor[1]-d:sensor[1]+d
        if manhattan_distance((x, yrow), sensor) <= distance && 
           !((x, yrow) in beacons || (x, yrow) in sensors)
       )
end

# solve_1("test.txt", 10)
solve_1("input.txt", 2000000)

######################################################

function ring_positions(sensor, beacon)
    distance = manhattan_distance(sensor, beacon)
    xs, ys = sensor

    return Iterators.flatten([ 
                              ((xs+t, ys+distance-(t-1)) for t in 1:distance+1),
                              ((xs+distance-(t-1), ys-t) for t in 1:distance+1),
                              ((xs-t, ys-distance+(t-1)) for t in 1:distance+1),
                              ((xs-distance+(t-1), ys+t) for t in 1:distance+1)
                             ])
end

function solve_2(file, xymax)
    sensors, beacons = load_file(file)

    sset = Set(sensors)
    bset = Set(beacons)
    distances = manhattan_distance.(sensors, beacons)

    rps = Iterators.unique(Iterators.flatten(
                           Iterators.map(ring_positions, sensors, beacons)
                          ))
    xys = Iterators.filter(rps) do rp
        rp[1] in 0:xymax && rp[2] in 0:xymax
    end

    tuning_xys = Iterators.filter(xys) do xy
        !(
          xy in sset || xy in bset || 
          any(zip(sensors, distances)) do sd
              (s, s_to_b_distance) = sd
              xy_to_s_distance = manhattan_distance(xy, s)
              xy_to_s_distance <= s_to_b_distance 
          end
         )
    end

    foreach(tuning_xys) do xy
        tuning_frequency = xy[1] * 4000000 + xy[2]
        println("For $file the distress location is $xy and the tuning frequency is \
                $tuning_frequency")
    end
end

# solve_2("test.txt", 20)
solve_2("input.txt", 4000000)
