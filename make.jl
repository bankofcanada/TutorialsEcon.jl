using Documenter
using StateSpaceEcon
using ModelBaseEcon
using TimeSeriesEcon

tutorials = []
for d in readdir("src")
    isdir(joinpath("src", d)) || continue
    title = open(joinpath("src", d, "main.md")) do f
        strip(readline(f), ['#', ' '])
    end
    push!(tutorials, string(title) => string(joinpath(d, "main.md")))
end



makedocs(
    sitename="StateSpaceEcon Tutorials",
    format=Documenter.HTML(prettyurls=get(ENV, "CI", nothing) == "true"),
    pages=[
        "index.md",
        "Tutorials" => tutorials,
        "Reference" => [
            "TimeSeriesEcon" => "timeseriesecon.md",
            "ModelBaseEcon" => "modelbaseecon.md",
            "StateSpaceEcon" => "statespaceecon.md",
        ]
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#= deploydocs(
    repo = "<repository url>"
) =#
