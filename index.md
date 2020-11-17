# Introduction

This section contains a list of tutorials demonstrating the use of
StateSpaceEcon group of Julia packages.

You could read the tutorials on the web - just browse the pages. If you wish to
run the tutorial examples and further experiment for yourself, follow the
instructions below to install a copy of the Tutorials on your computer.

## Getting started

### Prerequisites

You need a recent version of Julia (v1.0 or later). We also recommend using
VSCode and so below we provide the instructions assuming that's the case. To
install Julia and VSCode follow the instructions at
<https://github.com/julia-vscode/julia-vscode#installing-juliavs-codevs-code-julia-extensio>

### Installation

Clone either [DocsEcon.jl](https://github.com/bankofcanada/DocsEcon.jl) or
[TutorialsEcon.jl](https://github.com/bankofcanada/TutorialsEcon.jl).

TutorialsEcon.jl is a sub-module of DocsEcon.jl, mounted in `scr/Tutorial`. If
you decide to clone DocsEcon.jl, then you should make sure that you clone it
recursively.

```
$ git clone --recursive https://github.com/bankofcanada/DocsEcon.jl.git
```

If you use VSCode to clone the project, that doesn't happen automatically and
you'll see that `src/Tutorial` directory remains empty. In this case, open a
terminal in your DocsEcon.jl directory and run

```
$ git submodule init
$ git submodule update
```

After this, you should see the files of TutorialsEcon.jl appear under `src/Tutorials`.

### Initialize the environment

Open a Julia REPL in the root directory of your project. Activate the environment in 
the current directory and instantiate it.

```julia
julia> ]
pkg> activate .
pkg> instantiate
```

Note that if you're working with DocsEcon.jl, there's no need to do this in
`src/Tutorials`, even though that directory contains its own Julia environment.
All tutorials would run under the DocsEcon.jl environment just fine. If you find
that not to be the case, please open bug report issue in DocsEcon.jl.

If you're using VSCode, make sure to set the default Julia environment for the
workspace to the one you just instantiated.

### Running a tutorial

Each tutorial is in its own subdirectory, which is self-contained, meaning that
running a tutorial does not depend on files of another tutorial. 

Each tutorial has a `main.jl` file, which contains the tutorial code. The code
is meant to run in a REPL started in the root directory of the project, which is
the default in VSCode. In any case, make sure the currently active environment
is the one in the root directory of the project you cloned.
