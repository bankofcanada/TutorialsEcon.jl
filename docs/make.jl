using Documenter
using StateSpaceEconTutorials

makedocs(
    sitename = "StateSpaceEconTutorials",
    format = Documenter.HTML(),
    modules = [StateSpaceEconTutorials]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
