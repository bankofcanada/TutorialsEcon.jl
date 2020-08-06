using Documenter
using StateSpaceEcon
using ModelBaseEcon
using TimeSeriesEcon


makedocs(
    sitename="StateSpaceEcon Tutorials",
    format=Documenter.HTML(prettyurls=get(ENV, "CI", nothing) == "true"),
    pages = [
        "Tutorials" => [
            "Smets and Wouters 2007" => "US_SW07/main.md",
        ],
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
