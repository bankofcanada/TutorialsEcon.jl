# README

This project contains a list of tutorials demonstrating the use of StateSpaceEcon group of Julia packages.
Each tutorial is in its own subdirectory. They are meant to run in a Julia session running in the root
directory of the project, which is what happens in VSCode, not in the subdirectory of the specific tutorial.

## Installation

The tutorials are designed to run in the Julia environment in the root of the project.
Before the first use, make sure to instantiate the environment.
```julia
] activate .
] instantiate
```

After that, make sure the environment is active when you run the tutorial codes.

## List of tutorials

Each tutorial is in its own subdirectory and contains a `main.jl` and `main.md`
in addition to other files. The two `main` files contain the same code and
explanations. If running the tutorial code yourself, you should use the .jl
file.

* [Smets and Wouters 2007](US_SW07/main.md)
