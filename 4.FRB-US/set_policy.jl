
# Monetary policy switches
const dmp_switches = (:dmpintay, :dmptay, :dmptlr, :dmpalt, :dmpgen, :dmpex, :dmprr)

# Fiscal policy switches
const dfp_switches = (:dfpex, :dfpsrp, :dfpdbt)

"""
    set_mp!(data, switch[, range])

Set the monetary policy function over the given range. The given switch is set
to 1 and all other monetary policy switches are set to 0. If range is not given,
the switch is set over the full range of the data.

The set of valid switch values is in `dmp_switches`.
"""
function set_mp!(data::SimData, switch, range=rangeof(data))
    sw = Symbol(switch)
    if sw ∉ dmp_switches
        throw(ArgumentError("Not a valid Monetary Policy switch: $switch"))
    end
    data[range, dmp_switches] .= 0.0
    data[range, sw] .= 1.0
    return data
end

"""
    set_fp!(data, switch[, range])

Set the fiscal policy function over the given range. The given switch is set
to 1 and all other fiscal policy switches are set to 0. If range is not given,
the switch is set over the full range of the data.

The set of valid switch values is in `dfp_switches`.
"""
function set_fp!(data::SimData, switch, range=rangeof(data))
    sw = Symbol(switch)
    if sw ∉ dfp_switches
        throw(ArgumentError("Not a valid Fiscal Policy switch: $switch"))
    end
    data[range, dfp_switches] .= 0.0
    data[range, sw] .= 1.0
    return data
end

nothing
