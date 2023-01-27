
function load_longbase(longbase_filename, m::Model=FRBUS_VAR.model)
    models_path = joinpath(realpath(dirname(@__FILE__)), "models")
    longbase_lines = readlines(joinpath(models_path, longbase_filename));
    function fixdate(x)
        for subs in Dict("-01-01"=>"Q1", "-04-01"=>"Q2", "-07-01"=>"Q3", "-10-01"=>"Q4")
            x = replace(x, subs)
        end
        return x
    end
    start = eval(Meta.parse(longbase_lines[2][2:7]))
    if !(start isa MIT)
        start = eval(Meta.parse(fixdate(longbase_lines[2][1:10])))
    end
    data = SimData(start, m.varshks, zeros(Float64, length(longbase_lines)-1, length(m.varshks)))
    names = tuple(Symbol.(replace.(lowercase.(split(longbase_lines[1], ",")[2:end]), "\"" => ""))...)
    valid_names = Set(v.name for v in m.variables)
    for line = longbase_lines[2:end]
    # for line = longbase_lines[2:2]
        date = eval(Meta.parse(line[2:7]))
        if !(date isa MIT)
            date = eval(Meta.parse(fixdate(line[1:10])))    
        end
        values = split(line, ",")[2:end]
        @assert length(names) == length(values)
        for (n,v) in zip(names, values)
            if v == "NA" || n ∉ valid_names
                continue
            end
            data[date, n] = parse(Float64, v)
        end
    end
    data
end

nothing
