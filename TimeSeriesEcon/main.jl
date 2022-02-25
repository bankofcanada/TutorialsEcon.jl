## ################################################
# Load Packages

using TimeSeriesEcon
using Plots

## ################################################
#### Part 1: Moment In Time (MIT) and TSeries

### Initialize MITs and TSeries

# `MIT` is a primitive type based on 64-bit signed integers that 
# represents discrete dates. There are two ways to initialize 
# `MIT`s: (1) directly `2020M8`, or (2) using the functional form `mm(2020, 8)`.

# `Unit` Frequency
mit_integer = 2000U  # ii(2000)

# `Monthly` Frequency
mit_monthly = 2020M8 # mm(2020, 8)

# `Quarterly` Frequency
mit_quarterly = 2020Q3 # qq(2020, 3)

# `Yearly` Frequency
mit_yearly = 2020Y  # yy(2020)

# `TSeries` is subtype of AbstractVector and represents 1-dimensional time-series. A key 
# feature of `TSeries` is the ability to use `MIT`s as indices to get and set values.

# Note: TSeries converts all values to `Float64`. The automatic conversion feature might be
# changed in the future.

series_monthly = TSeries(2020M1, rand(1:10, 6))

# There are various ways to initialize `TSeries` - here, we provided an `MIT` that represents 
# the first date in the series and a vector of random values.

### Frequency

# Every instance of `MIT` and `TSeries` is equipped with `Frequency` information, stored as a parameter.

subtypes(Frequency)

frequencyof(2020M8)
frequencyof(series_monthly)

# As such, we can avoid performing operations on `TSeries` or `MIT`s of different frequencies.
# Also, haing `Frequency` parameter simplifies the retrieval of frequency specific information.

year(2020M8)
period(2020M8)

ppy(2020M8) # number of periods per year

## ################################################
#### Part 2: Indexing using MITs

### Access
# Just as integers are used to index into Julia vectors, `MIT`s are
# used to index into `TSeries`. 

# Indexing using a single `MIT` returns a float value associated with that date.
# Indexing using a range of `MIT`s will return another `TSeries` instance

series_monthly

series_monthly[2020M1] # 5
series_monthly[2020M1:2020M3] # TSeries(2020M8, [5.0, 4.0, 2.0])

### Assign

series_monthly[2020M1] = -1;
series_monthly

series_monthly[2020M2:end] = -1;
series_monthly

# You can also assign values outside of the bounds that were initially declared.
series_monthly[end+2] = -1;
series_monthly

## ################################################
#### Part 3: Plots and helpful functions

### Plotting support

# Using the Plots package, we can plot multiple `TSeries` 
# with varying frequency.

plot(TSeries(2000Q1, rand(1:3, 10)),
    TSeries(2000M1, rand(4:6, 30)),
    legend = true,
    title = "TSeries Plot",
    labels = ["Quarterly", "Monthly"],
    size = (600, 400)
)

png_fname = joinpath(pwd(), "TimeSeriesEcon", "tseries.png")
savefig(png_fname)

### Conversions

# Note that support for frequency conversions is under development. 

tsmonthly = TSeries(2020M1, collect(Float64, 1:12))

# Monthly -> Quarterly (high to low by mean (default method))
tsquarterly = fconvert(Quarterly, tsmonthly)

# Monthly -> Quarterly (high to low by sum)
fconvert(Quarterly, tsmonthly; method = :sum)

# Monthly -> Quarterly (high to low by first value)
fconvert(Quarterly, tsmonthly; method = :begin)

# Monthly -> Quarterly (high to low by last value)
fconvert(Quarterly, tsmonthly; method = :end)

# Quarterly -> Monthly (low to high by piecewise-constant)
fconvert(Monthly, tsquarterly)
