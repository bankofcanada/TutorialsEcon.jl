## ##########################################################################
#= 
    In this file we download the FRBUS package,
    unzip the model.xml file from it, and
    parse model.xml to create Julia module files containing the same models
    ready for use with StateSpaceEcon =#
## ##########################################################################

using HTTP      # to download frbus_package.zip file
using ZipFile   # to unzip model.xml
using LightXML  # to parse model.xml
using MacroTools

## ##########################################################################
# download the file if it doesn't already exist.

mypath = dirname(@__FILE__)

# If you're behind a firewall, download the zip file and place it in ./models/
zip_file = joinpath(mypath, "models", "frbus_package.zip")
if !isfile(zip_file)
    @info "Downloading FRBUS package"
    HTTP.download("https://www.federalreserve.gov/econres/files/frbus_package.zip", zip_file, update_period=Inf)
end
@assert isfile(zip_file)

## ##########################################################################
# unzip model.xml

zip_reader = ZipFile.Reader(zip_file)
xml_ind = findall([endswith(f.name, "model.xml") for f in zip_reader.files])
@assert length(xml_ind) == 1
model_xml = read(zip_reader.files[xml_ind[1]], String)

## ##########################################################################
# parse the xml file
xdoc = LightXML.parse_string(model_xml)
xroot = root(xdoc)
xml_variables = xroot["variable"]

nothing
## ##########################################################################
# process variables to extract equations, parameters, etc.

@info "Parsing model.xml file"

get_content(args...) = begin
    el = find_element(args...)
    return el === nothing ? nothing : content(el)
end

# empty containers
equation_types = Union{String,Nothing}[]
sectors = Union{String,Nothing}[]
coeffs = Dict()
# process variables and fill the containers on the fly
vars = Dict(map(enumerate(xml_variables)) do (i, v)
    # variable name
    name = get_content(v, "name")
    # variable meta data
    data = (; i=i,
        (Symbol(c) => get_content(v, c) for c in ("equation_type", "definition", "sector"))...)

    push!(sectors, data.sector)
    push!(equation_types, data.equation_type)

    eqn_string = nothing
    if data.equation_type != "Exogenous"
        eqn = find_element(v, "standard_equation")
        eqn_string = get_content(eqn, "eviews_equation")
        eqn_string = replace(eqn_string, r"\s+" => " ")
        eqn_string = replace(eqn_string, r"\s+\(" => "(")
        try
            eqn_string = Meta.parse(eqn_string)
        catch
            eqn_string = -2
        end
        foreach(get_elements_by_tagname(eqn, "coeff")) do c
            nm = get_content(c, "cf_name")
            nm = Meta.parse(nm)
            vl = get_content(c, "cf_value")
            vl = Meta.parse(vl)
            try
                if nm isa Expr && nm.head == :call && length(nm.args) == 2
                    nm, ind = nm.args
                    cf = get!(coeffs, nm, TSeries(1U, Float64[]))
                    cf[ind * U] = vl
                else
                    error("Coeff $nm in $((i, name))")
                end
            catch
                @error "At $((i, name)):"
                rethrow()
            end
        end
    end
    name => (; eqn=eqn_string, data...)
end)
unique!(sectors)
unique!(equation_types)

nothing
## ##########################################################################
# Convert EViews equations to StateSpaceEcon


cleanup_eqn(any) = nothing
cleanup_eqn(num::Number) = num
cleanup_eqn(sym::Symbol) = begin
    # replace variables with t-references, e.g. x => x[t]
    if "$sym" ∈ keys(vars)
        return Expr(:ref, sym, :t)
    end
    # replace _aerr by _a
    sym1 = replace("$(sym)", r"_aerr$" => "")
    if sym1 ∈ keys(vars)
        sym_a = Symbol("$(sym1)_a")
        return Expr(:ref, sym_a, :t)
    end
    return sym
end
function cleanup_eqn(ex::Expr)
    if ex.head == :block
        args = filter(x -> x !== nothing, cleanup_eqn.(ex.args))
        return length(args) == 1 ? args[1] : error("$ex")
    end
    if ex.head == :call
        fn, args = ex.args[1], ex.args[2:end]
        # replace EViews calls to d() and dlog() with calls to their ModelBaseEcon equivalents @d() and @dlog()
        if fn ∈ (:d, :dlog)
            args = filter(x -> x !== nothing, cleanup_eqn.(args))
            return Expr(:macrocall, Symbol("@", fn), nothing, args...)
        end
        # replace EViews lags and leads, with ModelBaseEcon equivalent t-reference, e.g. x(n) => x[t+n], x(-n) => x[t-n]
        if "$fn" ∈ keys(vars) && length(args) == 1
            return ModelBaseEcon.normal_ref(fn, args[1])
        end
        # replace EViews coefficient indexing with Julia equivalent indexing, e.g. y_x(i) => y_x[i]
        if fn ∈ keys(coeffs) && length(args) == 1
            return Expr(:ref, fn, args[1])
        end
        if @capture(ex, 1 / (1 + exp(-x_)))
            ret = Expr(:call, :heaviside, cleanup_eqn(x))
            # @info "Replacing" ex ret
            return ret
        end
        if @capture(ex, 1 / (1 + exp(x_)))
            ret = Expr(:call, :heaviside, Expr(:call, :-, cleanup_eqn(x)))
            # @info "Replacing" ex ret
            return ret
        end
        # If we're still here, this is a regular function call, e.g. log(x)
        args = filter(x -> x !== nothing, cleanup_eqn.(args))
        return Expr(:call, fn, args...)
    end
    if ex.head == :macrocall
    # replace @recode with Julia equivalent ifelse()
        if @capture(ex, @recode(l_ > r_, l_, r_))
            ret = Expr(:call, :max, cleanup_eqn(l), cleanup_eqn(r))
            # @info "Replacing" ex ret
            return ret
        end
        if @capture(ex, @recode(l_ < r_, l_, r_))
            ret = Expr(:call, :min, cleanup_eqn(l), cleanup_eqn(r))
            # @info "Replacing" ex ret
            return ret
        end
        if @capture(ex, @recode(c_, l_, r_))
            ret = Expr(:call, :ifelse, cleanup_eqn(c), cleanup_eqn(l), cleanup_eqn(r))
            # @info "Replacing" ex ret
            return ret
        end
    end
    return Expr(ex.head, cleanup_eqn.(ex.args)...)
end


## ##########################################################################
# write the model file

@info "Writing FRBUS_VAR.jl"

log_vars = split("""ebfi ebfin ec ecd ech ecnia ecnian eco egfe egfen egfet egfl egfln egflt
egse egsen egset egsl egsln egslt eh ehn em emn emo emon emp empn ex exn fgdp fgdpt fnicn
fniln fpc fpx ftcin fynicn fyniln fynin gfdbtn gfdbtnp gfexpn gfintn gfrecn gtn gtr jccan
jkcd kbfi kcd kh ki ks pcnia pcpi pcpix pcxfe pgdp pgfl pgsl phouse pl pmo pmp poil pxb
pxnc pxp qebfi qec qecd qeco qeh qpcnia qpl qpxb qpxnc qpxp qynidn tcin tpn wpo wpon wpsn
xb xbn xbo xbt xfs xfsn xgdi xgdin xgdo xgdp xgdpn xgdpt xgdptn xp xpn ydn yh yhibn yhl
yhln yhp yhpcd yhptn yhsn yht yhtn ykbfin ykin ynicpn ynidn yniln ynin ynirn ypn zyh zyhp
zyht""", r"\s+")

open(joinpath(mypath, "models", "FRBUS_VAR.jl"), "w") do fd
    f = IOContext(fd, :limit => false, :compact => false)

    println(f, "# FRBUS model")
    println(f)
    println(f, "module FRBUS_VAR")
    println(f, "using ModelBaseEcon")
    println(f)
    println(f, "model = Model()")
    println(f, "model.substitutions = true")
    println(f)
    println(f, "export heaviside")
    println(f, "\"Heaviside step function\" @inline heaviside(x) = convert(typeof(x), x>zero(x))")
    println(f)

    # parameters
    println(f, "@parameters model begin")
    foreach(keys(coeffs) |> collect |> sort) do pnm
        println(f, "    ", pnm, " = ", coeffs[pnm].values)
    end
    println(f, "end")
    println(f)

    # variables
    println(f, "@variables model begin")
    for eqn_type in equation_types
        if eqn_type == "Exogenous"
            continue
        end
        println(f, "    # ", eqn_type, " variables:")
        for v in keys(vars) |> collect |> sort
            if vars[v].equation_type == eqn_type
                print(f, "    ")
                if !isempty(vars[v].definition)
                    print(f, "\"")
                    escape_string(f, vars[v].definition, "\$")
                    print(f, "\" ")
                end
                if v in log_vars
                    println(f, "@log ", v)
                else
                    println(f, v)
                end
            end
        end
        println(f)
    end
    println(f, "end")
    println(f)

    # variables
    println(f, "@exogenous model begin")
    for eqn_type in equation_types
        if eqn_type != "Exogenous"
            continue
        end
        println(f, "    # ", eqn_type, " variables:")
        for v in keys(vars) |> collect |> sort
            if vars[v].equation_type == eqn_type
                print(f, "    ")
                if !isempty(vars[v].definition)
                    print(f, "\"")
                    escape_string(f, vars[v].definition, "\$")
                    print(f, "\" ")
                end
                println(f, v)
            end
        end
        println(f)
    end
    println(f, "end")
    println(f)

    # shocks
    println(f, "@autoshocks model _a")
    println(f)

    # equations
    println(f, "@equations model begin")
    for eqn_type in equation_types
        if eqn_type == "Exogenous"
            continue
        end
        println(f, "    # ", eqn_type, " equations:")
        for v in keys(vars) |> collect |> sort
            vv = vars[v]
            if vv.equation_type == eqn_type
                if !isempty(vv.definition)
                    print(f, "    \"")
                    escape_string(f, vv.definition, "\$")
                    println(f, "\"")
                end
                println(f, "    ", cleanup_eqn(vv.eqn))
            end
        end
        println(f)
    end
    println(f, "end")
    println(f)

    # initialize
    println(f, "@initialize model")
    println(f)

    println(f, "end")
    println(f)
end
