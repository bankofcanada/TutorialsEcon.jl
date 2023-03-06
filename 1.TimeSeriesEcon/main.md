# Time Series

In this tutorial we will see how to use the functionality provided in
TimeSeriesEcon to manipulate time series data.

All code presented here is also available in [`main.jl`](main.jl).

```@contents
Pages = ["main.md"]
Depth = 3
```

```@setup tse
using TimeSeriesEcon
using Statistics
using Plots
```

In this tutorial we need the following packages.
```julia
using TimeSeriesEcon
using Statistics
using Plots
```

## Frequency and Time

In a time series the values are evenly spaced in time and each value is labelled
with the moment in which it occurred. TimeSeriesEcon provides data types that
represent these concepts.

### Frequency
The abstract type [`Frequency`](@ref) represents the idea of the frequency of a
time series. All concrete frequencies are special cases. Currently we have four
calendar frequencies, [`Yearly`](@ref), [`HalfYearly`](@ref), [`Quarterly`](@ref), 
and [`Monthly`](@ref), which are all defined by a number of periods per year. 
We have three calendar frequencies which depend on a particular calendar date: 
[`Weekly`](@ref), [`BDaily`](@ref) and [`Daily`](@ref). Finally We also have the frequency 
[`Unit`](@ref), which is not based on the calendar and simply counts observations. 
Typically there's no need to work directly with these frequency types.

#### End-months and end-days
The frequencies [`Yearly`](@ref), [`HalfYearly`](@ref), and [`Quarterly`](@ref) have 
implicit default end months. These are 12, 6, and 3, respectively, corresponding to 
December, June and March. Uses of [`Yearly`](@ref) will in most cases implicitly use 
`Yearly{12}`. It is also possible to work with  frequencies with different end months, 
for example, a fiscal year might end in March, in which case a `Yearly{3}` frequency 
would be used. These end months have implications for frequency conversions (not yet 
implemented), but can in most cases be ignored.

The Weekly frequency similarly has an implicit default end-day of Sunday. Thus uses of 
[`Weekly`](@ref) will in most cases implicitly use `Weekly{7}`.

### Moments and Durations
In TimeSeriesEcon there are two data types to represent the notion of time. Data
of type [`MIT`](@ref) are labels for particular *moments in time*, while the
data type [`Duration`](@ref) represents the amount of time between two
[`MIT`](@ref)s. Both are generic types, in the sense that they are parametrized
by a frequency. For example

```@repl tse
typeof(2000Q1)
typeof(2021M5 - 2020M3)
```

#### Creating MIT instances
The most common types of MIT instances can be created using shorthands
of numbers followed immediately by `Y`, `H1`, `H2`, `Q1`, `Q2`, `Q3`, or `Q4`.
for example, the second half of 2022 would be `2022H2`.

```@repl tse
2022Q1
2022H1
2020Q3
2020Y
```

For variant end-months, append these in square brackets:

```@repl tse
2022Q1{2}
2022H1{5}
2020Y{11} 
```

For the the higher frequencies, a Date object or string is required to create them:

```@repl tse
weekly("2022-01-03")
bdaily("2022-01-03")
daily("2022-01-03")
```

Creating a BDaily MIT from a date that lands on a weekend will throw an error, this 
can be overcome with  passing the `bias` parameter. either `:previous`, `:next`, or `:nearest`.

```@repl tse
bdaily("2022-01-01", bias=:previous) # 2021-12-31
```

Daily and bdaily frequencies can also be created using string macros:

```@repl tse
d"2022-01-03"
bd"2022-01-03"
bd"2022-01-01"p # 2021-12-31
bd"2022-01-01"n # 2022-01-03
```

### Arithmetic with Time
We can perform arithmetic operations with values of type [`MIT`](@ref) and
[`Duration`](@ref). We just saw that the difference of two [`MIT`](@ref) values
is a [`Duration`](@ref) of the same frequency. Conversely, we can add an
[`MIT`](@ref) and a [`Duration`](@ref) to get an [`MIT`](@ref). We can add and
subtract two [`Duration`](@ref)s, but we're not allowed to add two
[`MIT`](@ref)s, only subtract them.

```@repl tse
a = 2001Q2 - 2000Q1  # the result is a Duration{Quarterly}
b = 2001Q2 + 2000Q1  # doesn't make sense!
```

When we have an [`MIT`](@ref) plus or minus a plain `Integer`, the latter is
automatically converted to a [`Duration`](@ref) of the appropriate frequency.
This should make our code more readable.
```@repl tse
2000Q1 + Duration{Quarterly}(6)  # this is clunky
2000Q1 + 6 # same as above
```

We're not allowed to mix frequencies.
```@repl tse
2000Q1 + Duration{Monthly}(6)
```

Other arithmetic operations involving [`MIT`](@ref)s and [`Duration`](@ref)s,
either with each other or with `Integer`s are not allowed.
```@repl tse
2000Q1 * 5
```

### Other Operations
The function [`frequencyof`](@ref) returns the frequency type of its argument.
```@repl tse
frequencyof(2000Y)
frequencyof(2020Q1 - 2019Q3)
```

There are a few operations which are valid only for calendar frequencies. 
The function [`ppy`](@ref) returns the number of periods, while
[`TimeSeriesEcon.year`](@ref) and [`period`](@ref) return the year and the period number. The
periods are numbered from `1` to `ppy`. If we need both, we can use
[`mit2yp`](@ref).
```@repl tse
t = 2020Q3
ppy(t)
TimeSeriesEcon.year(t)
period(t)
mit2yp(t)
```

Note that `ppy` returns hardcoded numbers for weekly, daily, and bdaily frequencies,
regardless of the actual year of the MIT passed. In addition, the `TimeSeriesEcon.year`,
`period`, and `mit2yp` functions do not work for Weekly frequencies, due uncertainty 
surrounding weeks spanning the end of a year.

## Ranges
We can create a range of [`MIT`](@ref) the same way we create ranges of
integers. The standard Julia operations with ranges work on [`MIT`](@ref) ranges
as well.

```@repl tse
rng = 2000M1:2001M9
length(rng)
first(rng)
last(rng)
rng[3:5]   # subrange
rng .+ 6  # shift forward by 6 periods
```

We can also create a range where the step is not 1 but some other integer.
Technically the step should be a [`Duration`](@ref), but once again we can use
an `Integer` for convenience.
```@repl tse
rng2 = 2000M1:2:2000M8
collect(rng2)
```

We can create a range that runs backwards by swapping the endpoints and making
the step `-1`. But it is easier to call the standard Julia function
[`reverse`](https://docs.julialang.org/en/v1/base/iterators/#Base.Iterators.reverse).
This can be helpful when using [`@rec`](@ref) as shown below.
```@repl tse
rng
reverse(rng)
```

We can also use the string macros to create ranges of Daily and BDaily frequencies.
When creating a BDaily range in this way, the first date will be rounded up and 
the last date rounded down whenever these fall on a weekend.

```@repl tse
d"2022-01-01:2022-01-31"
bd"2022-01-01:2022-01-31"
```

## Time Series

TimeSeriesEcon provides the data type [`TSeries`](@ref) to represent a
macro-economic time series. It is similar to a
[`Vector`](https://docs.julialang.org/en/v1/base/arrays/#Base.Vector), but with
added functionality for time series.

The [`TSeries`](@ref) type inherits from the built-in
[`AbstractArray`](https://docs.julialang.org/en/v1/base/arrays/#Core.AbstractArray)
and supports all the basic operations of 1-dimensional arrays in Julia. Refer to
the article on
[Multi-dimensional Arrays](https://docs.julialang.org/en/v1/manual/arrays/#man-multi-dim-arrays)
in the Julia manual for details.

Type [`TSeries`](@ref) is also a generic data type. It depends on two
type-parameters: its frequency and the data type of its elements.

### Creation of `TSeries`

#### Constructors

The basic constructor of a [`TSeries`](@ref) requires an [`MIT`](@ref) (to label
the first observation) and a vector of data.
```@repl tse
vals = rand(5)
ts = TSeries(2020Q1, vals)
```
The frequency of the given [`MIT`](@ref) determines the frequency of the
[`TSeries`](@ref). Similarly, the type of the elements of the `vals` array
determines the element type of the [`TSeries`](@ref).

!!! note "Important Caveat"

    Be mindful of the fact that the [`TSeries`](@ref) does not copy the original
    data container. Rather, the `ts` constructed above is just a wrapper and
    uses `vals` for its storage. Specifically, every modification to one of them
    is immediately reflected in the other. To break the connection use
    [`copy`](https://docs.julialang.org/en/v1/base/base/#Base.copy).

    ```@repl tse
    ts = TSeries(2020Q1, copy(vals))
    ```

We can construct a [`TSeries`](@ref) with its own storage from just an
[`MIT`](@ref) range. This would construct a [`TSeries`](@ref) whose storage is
un-initialized (it would contain some arbitrary numbers). We can initialize the
storage by providing a constant or a function, such as
[`zeros`](https://docs.julialang.org/en/v1/base/arrays/#Base.zeros),
[`ones`](https://docs.julialang.org/en/v1/base/arrays/#Base.ones),
[`rand`](https://docs.julialang.org/en/v1/stdlib/Random/#Base.rand).

```@repl tse
rng = 2020Q1:2021Q4
TSeries(rng)  # uninitialized (arbitrary numbers that happen to be in memory)
TSeries(rng, pi)    # constant
TSeries(rng, rand)  # random numbers
```

!!! note "Important"

    Be mindful of the type of the constant you provide as initializer.
    Specifically, in Julia `0` is of type
    [`Int`](https://docs.julialang.org/en/v1/manual/integers-and-floating-point-numbers/)
    while `0.0` is of type
    [`Float64`](https://docs.julialang.org/en/v1/manual/integers-and-floating-point-numbers/).
    If you're never going to work with [`TSeries`](@ref) that store integers
    (most people), then we recommend you get used to the idiom
    `TSeries(rng, zeros)`, which does what you expect.

    ```@repl tse
    TSeries(rng,0)   # element type is Int
    TSeries(rng, zeros) # element type is FLoat64
    ```

#### Other ways to construct `TSeries`

We can also construct new [`TSeries`](@ref) from existing [`TSeries`](@ref). The
function [`similar(::TSeries)`](@ref) creates an uninitialized copy, meaning
that the copy has the same frequency and element type, but the storage contains
arbitrary values. This is useful if we just want a [`TSeries`](@ref) that we
will fill in later. The other useful function is
[`copy`](https://docs.julialang.org/en/v1/base/base/#Base.copy), which makes an
exact copy. In both cases the new and the old [`TSeries`](@ref) have separate
storage.
```@repl tse
t = TSeries(rng, 2.7)
s = similar(t)
c = copy(t)
```

New [`TSeries`](@ref) are also the results of arithmetic and other operation,
which we discuss later in this tutorial.

### Access to Elements of `TSeries`

#### Reading (Indexing)
We can access the value for a specific [`MIT`](@ref) using the standard indexing
notation in Julia.
```@repl tse
rng = 2000Q1:2001Q1;
t = TSeries(rng, rand)
t[2000Q1]
```

If we ask for a range of [`MIT`](@ref), the result is a new [`TSeries`](@ref).
```@repl tse
t[2000Q2:2000Q4]
```

We can also use integers. In this case the [`TSeries`](@ref) behaves like a
`Vector`. The valid integer bounds are `1:length(ts)`. Note that if we use an
integer range, the result is a `Vector`, not a [`TSeries`](@ref).
```@repl tse
t[1]
t[2:4]
```

If we attempt to read outside the stored range, we would get a `BoundsError`,
which is the same for `Vector`s.
```@repl tse
t[1999Q1]
t[2001Q1:2001Q3]
```

When specifying a range, we can use `begin` and `end` inside the `[]`. This
works exactly the same way for [`TSeries`](@ref) as it does for the built-in
`Vector`.
```@repl tse
t[end-2:end]   # last 3 
t[begin+1:end-1]  # drop first and last
```

!!! note "Important"

    Keep in mind that `begin` and `end` for [`TSeries`](@ref) are of type
    [`MIT`](@ref). Specifically, when using them we must make sure that both
    limits of the range evaluate to [`MIT`](@ref) and not integer. For example,
    ```julia ts[1:end-1]  # error ```
    will result in an error because the first limit is 1, an `Int`, while the
    last limit is `lastdate(ts)-1`, an [`MIT`](@ref)). To make this work we need
    this.
    ```julia ts[begin:end-1] # correct ``` 

#### Writing (Indexed Assignment)

When indexing is used on the left side of an assignment, we're updating the
specified element(s) of the [`TSeries`](@ref). Again, this works the same as
with `Vector`s.
```@repl tse
t[2000Q2] = 5
t
```
When assigning to multiple locations (e.g., over a range), we must ensure that
the number of values provided on the right-hand side is correct. Otherwise we
would get an error.
```@repl tse
t[begin:begin + 2] = [1, 2, 3]
t
```

If we want to assign a single value to multiple locations we have to make the
assignment a
[`vectorized "dot" operation`](https://docs.julialang.org/en/v1/manual/mathematical-operations/#man-dot-operators).
For this we use `.=` instead of `=`.
```@repl tse
t[end-2:end] .= 42
t
```
The same way we can reset the entire [`TSeries`](@ref) to a constant using `.=`
without specifying the range. This would update the existing [`TSeries`](@ref) in
place.
```@repl tse
t .= pi
```
Without the dot, i.e., `t = pi`, `t` would become a completely different
variable with value `pi`.

Unlike `Vector`s, with [`TSeries`](@ref) we are allowed to assign outside the
stored range. Doing this resizes the [`TSeries`](@ref) as necessary. If there is
a gap, that is a part of the new range which is neither in the old range nor in
the assignment range, it is filled with `NaN`.
```@repl tse
t[1999Q1:1999Q2] .= -3.7
t
```
This only works with [`MIT`](@ref) indexing. If an integer index is out of
bounds, the attempted assignment will result in the usual `BoundsError`, which
is what we would get with a `Vector`.
```@repl tse
t[15] = 3.5   # results in an error
```

The vectorized "dot" assignment allows us to copy values from another
[`TSeries`](@ref). In this case, the specified range on the left of `.=` applies
to the right side too. In other words, the values from the right hand side will
be taken from the range of the assignment.
```@repl tse
q = TSeries(rangeof(t), 100)
t[1999Q3:2000Q2] .= q
t
```

## Arithmetic with `TSeries`

There are two kinds of arithmetic operations with [`TSeries`](@ref). One kind is
where we treat the time series as a single object. Similarly to vectors, we have
addition of time series and multiplication of a time series by a
scalar number. The other kind of arithmetic is where we treat the time series as
a collection of numbers and do the operations element-wise.

In both cases, if there are multiple time series involved in an expression they
must all be of the same frequency, otherwise the operation is generally not well
defined.

When we add (or subtract) two or more [`TSeries`](@ref) their ranges are not
required to be identical. The resulting [`TSeries`](@ref) has a range containing
the common part of all ranges. This is in spirit with the idea that we treat
values of a time series outside of its range as unknown or missing, so the
result of arithmetic with unknown values remains unknown.
```@repl tse
x = TSeries(20Q1:20Q4, rand)
y = TSeries(20Q3:21Q2, rand)
x + y
x - y
```

When we multiply (or divide) a [`TSeries`](@ref) by a scalar the resulting
[`TSeries`](@ref) has the same range as the original.
```@repl tse
2y
y/2   
```

For element-wise operations we use Julia's
["dot" notation](https://docs.julialang.org/en/v1/manual/mathematical-operations/#man-dot-operators).
This notation is used for vectorized and broadcasting operations. The time
series are aligned so that element-wise operations are performed on matching
[`MIT`](@ref) across all [`TSeries`](@ref) in the expression. For this reason,
once again, they all must have the same frequency and the range of the result is
the intersection of all ranges.
```@repl tse
log.(x)   # use dot for vectorized function call
1 .+ x    # broadcasting addition of scalar 1 to time series x 
x .+ y    # vectorized addition (same as regular addition of TSeries)
2 ./ y    # broadcasting division division
y .^ 3    # broadcasting y-cubed
```

When assigning the result of a broadcasting operation within an existing
[`TSeries`](@ref) we have to use `.=` and may optionally specify a range on the
left-hand side. When we specify a range on the left-hand side the
[`TSeries`](@ref) on the left is resized, if necessary, to include the given
range.
```@repl tse
z = copy(x)
z .=  1 .+ y  # assign only within the common range of x and y
z
z[rangeof(y)] .= 3 .+ y  # resize x and assign within the full range of y
z
```

Broadcasting operations also can be done with mixing [`TSeries`](@ref) and
`Vector`s in the same expression. In this case, the `Vector` must be of the same
length as the [`TSeries`](@ref) and the result is a [`TSeries`](@ref).
```@repl tse
v = 3ones(size(x))
x .+ v
```

## Time Series Operations

### Shifts

The lag or lead of a [`TSeries`](@ref) is an operation where the data remains
the same but the [`MIT`](@ref) labels are shifted accordingly. Functions
[`lag`](@ref) and [`lead`](@ref) produce a new [`TSeries`](@ref), while
[`lag!`](@ref) and [`lead!`](@ref) modify the given [`TSeries`](@ref) in place.
A second integer argument `n` can be provided to indicate which lag or lead is
desired, if something other than 1.
```@repl tse
lag(x)
lead(x)
```

### Diff and Undiff

The first difference of a [`TSeries`](@ref) can be computed with the built-in
function [`diff`](https://docs.julialang.org/en/v1/base/arrays/#Base.diff). The
built-in version works for any `Vector`, including [`TSeries`](@ref). In
addition, for time series version of [`diff`](@ref) allows a second integer
argument `k` to indicate which lag or lead to subtract. The default is `k=-1`,
where a negative value of `k` indicates a lag and a positive value indicates a
lead.
```@repl tse
dx = diff(x)
```

The inverse operation can be done with the function [`undiff`](@ref). In its
basic form it is the same as the built-in function
[`cumsum`](https://docs.julialang.org/en/v1/base/arrays/#Base.cumsum).
```@repl tse
undiff(dx)
```
We can see that the answer above does not equal `x`. This is because the first
value of `x` was lost. [`undiff`](@ref) allows us to specify an "anchor" in the
form of `date => value`. In this case the resulting [`TSeries`](@ref) will have
the given value at the given date.
```@repl tse
x2 = undiff(dx, firstdate(x) => first(x))
x ≈ x2
```

!!! note "Good to know"

    In the call to [`undiff`](@ref) above we used
    [`first`](https://docs.julialang.org/en/v1/base/collections/#Base.first),
    which is a built-in Julia function that returns the first value of a
    collection. We also used [`firstdate`](@ref), which works for
    [`TSeries`](@ref) and returns the first date in the stored range of its
    argument.

### Moving Average

Moving average can be computed with a call to the function [`moving`](@ref). It
takes a second integer argument `n` which indicates the length of the window
over which the moving average will be computed. If `n` is positive, the window
is backwards-looking (includes lags), while negative `n` uses a forward-looking
window (includes leads). The window always includes the current value (lag 0).
```@repl tse
tt = TSeries(2020Q1, collect(Float64, 1:10))
moving(tt, -4)
moving(tt, 6)
```

### Recursive assignments

Sometimes we need to construct a time series by recursive assignments. We can do
this on one line with the macro [`@rec`](@ref). For example, we can simulate the
impulse response of a simple AR(1) model. Say
```math a_t = (1-\rho) a_{ss} + \rho a_{t-1} + \varepsilon_t.```
Then we can compute the impulse response with the following snippet of code.
```@repl tse
a_ss = 1.0
ρ = 0.6
a = fill(a_ss, 2020Q1:2022Q1)
a[begin] += 0.1
for t = firstdate(a)+1:lastdate(a)
    a[t] = (1-ρ)*a_ss + ρ*a[t-1]
end
a
```
We can rewrite the last loop more succinctly like this:
```@repl tse
@rec rangeof(a, drop=1) a[t] = (1-ρ)*a_ss + ρ*a[t-1]
a
```
The first argument of [`@rec`](@ref) is the range over which the loop will run.
In this case we're using `rangeof(a, drop=1)`. Function [`rangeof`](@ref)
normally returns the stored range of a [`TSeries`](@ref). With the optional
parameter `drop=n` we request that the first `n` periods be skipped. If `n` is
negative, then the periods will be skipped at the end.
```@repl tse
(rangeof(a), rangeof(a, drop=1), rangeof(a, drop=-1))
```

Note also that whether using [`@rec`](@ref) or spelling out the for-loop
explicitly, the [`TSeries`](@ref) will be resized if necessary. However, it is
more efficient to preallocate the entire range by calling [`resize!`](@ref)
first.
```@repl tse
resize!(a, 2020Q1:2023Q1)
@rec rangeof(a, drop=1) a[t] = (1-ρ)*a_ss + ρ*a[t-1]
a
```

## Multi-variate Time Series

We can store multiple time series in a variable of type [`MVTSeries`](@ref).
This is a collection of [`TSeries`](@ref) with the same frequency, the same
range, and the same element type. It is like a table, where each row corresponds
to an [`MIT`](@ref) and each column to a time series variable.

### Creation of `MVTSeries`

The basic constructor of [`MVTSeries`](@ref) takes an [`MIT`](@ref), which
indicates the label of the first row, a list of names for the columns, and a
matrix of values. The number of columns in the given matrix must match the
number of column names. The range of the resulting [`MVTSeries`](@ref) is
determined from the first date and the number of rows.
```@repl tse
x = MVTSeries(2020Q1, (:a, :b), rand(6, 2))
```

Similarly to [`TSeries`](@ref), if we specify a range (rather than a single
[`MIT`](@ref)), the [`MVTSeries`](@ref) will be able to allocate its own
storage. In this case, we can optionally provide an initializer in the form of a
constant value or a function.
```@repl tse
MVTSeries(2020Q1:2021Q3, (:one, :too, :tree), zeros)
```

We can also build an [`MVTSeries`](@ref) from a range and a list of name-value
pairs. The values can be [`TSeries`](@ref), vectors, or constants. In the case
of a [`TSeries`](@ref), the constructor will use the necessary range, while in
the case of a vector must have the correct length. This form of the
[`MVTSeries`](@ref) constructor allocates its own storage space, so the data are
always copied.
```@repl tse
data = MVTSeries(2020Q1:2021Q1;
            hex = TSeries(2019Q1, collect(Float64, 1:20)),
            why = zeros(5),
            zed = 3, )
```

New `MVTSeries` variables can also be created with
[`similar(::MVTSeries)`](@ref) and
[`copy`](https://docs.julialang.org/en/v1/base/base/#Base.copy). They are also
the result of arithmetic operations. This is the same as with
[`TSeries`](@ref), so we won't spend time repeating it.

### Access

[`MVTSeries`](@ref) behaves like a 2-dimensional matrix when indexing is done
with integers. Otherwise, we can also index using [`MIT`](@ref)s (or
[`MIT`](@ref) ranges) for the row-indexes and
[`Symbol`](https://docs.julialang.org/en/v1/manual/metaprogramming/#Symbols)s
(or tuples of
[`Symbol`](https://docs.julialang.org/en/v1/manual/metaprogramming/#Symbols)s)
for the column-indexes.
```@repl tse
data[2020Q2, :hex]
```

An entire row can be accessed with a single [`MIT`](@ref) index. 
The result of such indexing is a regular `Vector`.  In order to extract 
an [`MVTSeries`](@ref) the index must be a unit range of [`MIT`](@ref).
```@repl tse
data[2020Q2]
data[2020Q2:2020Q2]  # index with range
```

Similarly, we can extract an entire column by its name. The result is a [`TSeries`](@ref).  
If the index is a
[tuple](https://docs.julialang.org/en/v1/manual/functions/#Tuples) of names,
then the result is another [`MVTSeries`](@ref) containing only the selected
columns.
```@repl tse
data[:zed]  
data[(:zed,)] # index with tuple
```

For convenience we can also access the columns by name using the traditional
`data.zed` notation.
```@rept tse
data.zed
```

It is sometimes necessary to iterate over the columns of an
[`MVTSeries`](@ref). This can be done easily with the function
[`columns`](@ref). The following snippet of code shows an idiom for such
iteration.
```@repl tse
using Statistics
for (name, value) in columns(data)
    println("Average of `", name, "` is ", mean(value), ".")
end
```
!!! note

    Note that [`columns`](@ref) is specific to `MVTSeries`. The built-in
    function
    [`pairs`](https://docs.julialang.org/en/v1/base/collections/#Base.pairs)
    does the same for a general collection of name-value pairs. It also works
    for [`MVTSeries`](@ref).

## Plotting

Visualizing a [`TSeries`](@ref) is straight-forward.
```@repl tse
plot(a, 1 .+ 0.1*TSeries(2020M1:2023M1, rand), label=["a" "rand"]);
savefig(ans, "plot-1.png"); # hide
```
[![](plot-1.png)](plot-1.png)


Similarly, we can plot all time series in an [`MVTSeries`](@ref) just as easily.  
Each variable will appear in its own set of axes.
```@repl tse
db_a = MVTSeries(2020Q1:2023Q4, 
    x = 0.5, 
    y = 0:1/15:1,
    z = rand(16),
)
plot(db_a, label=["db_a"]);
savefig(ans, "plot-2.png"); nothing; # hide
```
[![](plot-2.png)](plot-2.png)

We cal also plot several [`MVTSeries`](@ref) at the same time.
```@repl tse
db_b = MVTSeries(2020Q1:2023Q4, 
    y = 0.5,
    z = 1:-1/15:0, 
    w = rand(16),
)
plot(db_a, db_b, label=["db_a" "db_b"]);
savefig(ans, "plot-3.png"); nothing; # hide
```
[![](plot-3.png)](plot-3.png)

We see that all variables are plotted as long as they appear in at least one of
the given [`MVTSeries`](@ref). The plot can become very busy very quickly. There
is also a limit of 10 variables (which will result in a 5``\times``2 grid). We
can select which variables to plot with the option `vars=`. We can also restrict
the range of the plot with `trange=`. Any other plot attributes work as usual.
```@repl tse
plot(db_a, db_b, 
    label = ["db_a" "db_b"],
    vars = [:y, :z],
    trange = 2020Q3:2022Q3,
    layout = (2,1),
    right_margin = 1Plots.cm,   # hide
    left_margin = 0.5Plots.cm,  # hide
);
savefig(ans, "plot-4.png"); nothing; # hide
```
[![](plot-4.png)](plot-4.png)

!!! note "Good to Know"

    The `trange=` argument works only when all time series in the plot have the
    same frequency. When plotting time series with different frequencies, you
    can use `xlim=`. You can use [`MIT`](@ref) in the limits specified by `xlim`
    - they are converted to floating point numbers automatically. For example
      `float(2020Q1) == 2020.0`, `float(2020Q2) = 2020.25`, etc. An important
      difference to keep in mind is that `trange=` requires a unit range, e.g.,
      `trange=2020Q3:2022Q3`, while `xlim=` requires a tuple, e.g.,
      `xlim=(2020Q3,2022Q3)`.

## `Workspace`s

When working with models, in addition to time series data, we encounter a lot of
other types of data. For example, parameter and steady state values, simulation
ranges and dates, etc. The data type [`Workspace`](@ref) is a container that
can store all kinds of data. Most operations for
[dictionaries](https://docs.julialang.org/en/v1/base/collections/#Dictionaries)
work also for [`Workspace`](@ref)s.

We can create an empty [`Workspace`](@ref) and fill it with data. We can create
_"variables"_ in the workspace directly by assignment.
```@repl tse
w = Workspace()
w.rng = 2020Q1:2021Q4
w.start = first(w.rng)
w.a = TSeries(w.rng)
w.a .= a
w
```
We can remove data from the workspace using the built-in function
[`delete!`](https://docs.julialang.org/en/v1/base/collections/#Base.delete!).
```@repl tse
delete!(w, :start)
```

We can also give the constructor of [`Workspace`](@ref) a list of names and
values like this:
```@repl tse
Workspace(rng = 2020Q1:2021Q4, alpha = 0.1, v = TSeries(2020Q1, rand(6)))
```
Equivalently, we can provide the whole list of name-value pairs as a single
argument:
```@repl tse
datalist = [:rng => 2020Q1:2021Q4, :alpha => 0.1, :v => TSeries(2020Q1, rand(6))]
Workspace(datalist)
```

The last one is particularly useful for converting an [`MVTSeries`](@ref) to a
[`Workspace`](@ref), since we can use the [`pairs`](@ref) function.
```@repl tse
w_a = Workspace(pairs(db_a; copy = true))
```
Note that by default `copy=false`, which means that the time series in the new
`w_a` would share their storage with the corresponding columns of `db_a`. This
is more efficient than copying the data. However, if we need the new workspace
to hold its own copy of the data, we can force that by setting `copy=true`.

The next example is an idiom for converting a workspace back to an
[`MVTSeries`](@ref). Note that in this case we always get a copy, so there's no
optional parameter `copy=`.
```@repl tse 
MVTSeries(rangeof(w_a); pairs(w_a)...)
```
In the above we used [`rangeof(::Workspace)`](@ref) on the `Workspace` variable
`w_a`, which returns the intersection of the ranges of all variables in the
workspace. 

### `MVTSeries` vs `Workspace`

You've probably already noticed the remarkable similarity between
[`MVTSeries`](@ref) and [`Workspace`](@ref). Both are containers for
[`TSeries`](@ref) and in many ways are interchangeable. In both cases we can
access data by name using the traditional "dot" notation (e.g.,
`db.x`), and we can also access them using indexing notation (e.g., db[:x]).

One important differences are that `MVTSeries` is a matrix, so we can use it for
[linear algebra](https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/) and
[statistics](https://docs.julialang.org/en/v1/stdlib/Statistics/).
[`MVTSeries`](@ref) also has the constraint that all variables are
[`TSeries`](@ref) with the same frequency.

In contrast, [`Workspace`](@ref) is a dictionary, which can store variables of
any type. So in a workspace we can have multiple time series of different
frequencies. Also, a [`Workspace`](@ref) can contain nested [`MVTSeries`](@ref)
or [`Workspace`](@ref)s.

Another important difference is that we can add and delete variables in a
workspace, while in an [`MVTSeries`](@ref) the columns are fixed and in order to
add or remove any column we must create a new [`MVTSeries`](@ref) instance.

## `overlay`

Function [`overlay`](@ref) has two modes of operation: one is when all inputs
are [`TSeries`](@ref) and the other is when the arguments are a mixture of
[`Workspace`](@ref) and [`MVTSeries`](@ref).

In the first case all time series must have the same frequency and the result is
a new [`TSeries`](@ref) whose range is the union of all ranges of the inputs.
For each [`MIT`](@ref) the output will have the first non-missing value found in
the inputs from left to right. (`NaN` is considered missing, as well as values
outside the allocated range.)
```@repl tse
x1 = TSeries(2020Q1:2020Q4, 1.0)
x1[2020Q2:2020Q3] .= NaN
x2 = TSeries(2019Q3:2020Q2, 2.0)
x2[2019Q4:2020Q1] .= NaN
x3 = TSeries(2020Q2:2021Q1, 3.0)
MVTSeries(; x1, x2, x3, overlay = overlay(x1, x2, x3))
```
We can force the output to have a specific range by putting that range as the
first argument of [`overlay`](@ref)
```@repl tse
overlay(2020Q1:2020Q4, x1, x2, x3)
```

In the second case, when we call [`overlay`](@ref) on a list of
[`MVTSeries`](@ref) or [`Workspace`](@ref) variables, the result is a
[`Workspace`](@ref) in which all variables are recursively overlaid. For
example, a variable in the result is taken form the first input (from left to
right) in which it is found. But if that variable is a [`TSeries`](@ref), then
it is overlaid from all inputs in which it appears. The same applies to other
"overlay-able" data types, such as nested [`Workspace`](@ref)s and
[`MVTSeries`](@ref).
```@repl tse
w1 = Workspace(; x = x1, a = 1)
w2 = MVTSeries(; x = x2, b = 2)    # w2.b is a `TSeries`!
w3 = Workspace(; x = x3, a = 3, b = 3, c = 3)
overlay(w1, w2, w3)
```
In the example above, `x` is a [`TSeries`](@ref) in all three inputs and so it
is overlaid; `a` is a scalar taken from `w1`; `b` is a [`TSeries`](@ref) in `w2`
and a scalar in `w3`, so it is not overlaid and instead it is simply taken from
`w2`, because that's where it appears first; and finally `c` is taken from `w3`,
since it is missing from the other two.

## `compare` and `@compare`

The [`compare`](@ref) function and the accompanying [`@compare`](@ref) macro can
be used to compare two [`Workspace`](@ref)s or [`MVTSeries`](@ref). The
comparison is done recursively.
```@repl tse
v1 = Workspace(; 
        x = 3, 
        y = TSeries(2020Q1, ones(10)), 
        z = MVTSeries(2020Q1, (:a, :b), rand(6,2)));
v2 = deepcopy(v1);    # always use deepcopy() with Workspace
v2.y[2020Q3] += 1e-7
v2.z.a[2020Q3] += 0.001
v2.b = "Hello"
@compare(v1, v2)
```

Numerical values, including [`TSeries`](@ref), are compared using
[`isapprox`](https://docs.julialang.org/en/v1/base/math/#Base.isapprox). We can
pass arguments to
[`isapprox`](https://docs.julialang.org/en/v1/base/math/#Base.isapprox) by
adding them as optional parameters to the function call. For example, we can set
the absolute tolerance of the comparison with `atol=`.
```@repl tse
@compare(v1, v2, atol=1e-5)
```
Keep in mind that when comparing two `NaN` values the result is `false`. This
can be changed by setting `nans=true`. 


Other useful parameters include `ignoremissing`, which can be set to `true` in
order to compare only variables that exist in both inputs, and `showequal` which
can be set to `true` to report all variables, not only the ones that are
different. [`compare`](@ref) and [`@compare`](@ref) return `true` if the two
databases compare as equal and `false` otherwise.
```@repl tse
@compare(v1, v2, showequal, ignoremissing, atol=0.01)
```

## BDaily Holidays
BDaily TSeries have values falling on weekdays (Monday-Friday). In some use cases 
there may be `NaN` values on holidays and/or NaN values on other days of
the year. Some functions take additional arguments which determine the treatment 
of such `NaN` values.

These options are:
* `skip_all_nans` - either `true` or `false`.
* `skip_holidays` - either `true` or `false`.
* `holidays_map` - either `Nothing` or `or a TSeries{BDaily, Bool}`.

These options are available for the functions 
[`cleanedvalues`](@ref),  
[`shift`](@ref), 
[`lag`](@ref), 
[`lead`](@ref), 
[`pct`](@ref), 
[`diff`](@ref), 
[`mean`](https://docs.julialang.org/en/v1/stdlib/Statistics/#Statistics.mean), 
[`std`](https://docs.julialang.org/en/v1/stdlib/Statistics/#Statistics.std), 
[`stdm`](https://docs.julialang.org/en/v1/stdlib/Statistics/#Statistics.stdm), 
[`var`](https://docs.julialang.org/en/v1/stdlib/Statistics/#Statistics.var), 
[`varm`](https://docs.julialang.org/en/v1/stdlib/Statistics/#Statistics.varm), 
[`median`](https://docs.julialang.org/en/v1/stdlib/Statistics/#Statistics.median), 
[`quantile`](https://docs.julialang.org/en/v1/stdlib/Statistics/#Statistics.quantile), 
[`cor`](https://docs.julialang.org/en/v1/stdlib/Statistics/#Statistics.cor), and 
[`cov`](https://docs.julialang.org/en/v1/stdlib/Statistics/#Statistics.cov).

The `cleanedvalues` function returns the values of the TSeries, excluding any values
specified to be excluded as per the three options above.

#### `skip_all_nans`
When `true`, all NaN values will be skipped for the relevant calculations. For the `shift`, `diff`,
and `pct` functions, the NaN values will be replaced with the nearest non-NaN value, in the direction
of the shift. For example, when shifting the data forward (or leading), the replacement values will come from 
the later period(s), whereas when shifting data backwards (or lagging, or using the `diff` or `pct` functions) 
the replacement will come from the earlier periods. In this way, the `pct` value for a given day
will be calculated against the previous non-NaN value.

#### `skip_holidays`
When `true`, values on holidays will be skipped for the relevant calculations. For the `shift`, `diff`,
and `pct` functions, the values on holidays will be replaced with the nearest non-holiday value, similar
to the treatment of NaN values in the skip_all_nans option. NaN values on non-holidays will still be 
treated as `NaN`.

Holidays are determined based on the holidays map stored in `TimeSeriesEcon.getoption(:bdaily_holidays_map)`.

#### `holidays_map`
This option functions like `skip_holidays=true` except that the passed holidays map is used, rather than
the map stored in `TimeSeriesEcon.getoption(:bdaily_holidays_map)`.

```@repl tse
ts = TSeries(bd"2022-01-03", collect(1.0:10.0))
ts[bd"2022-01-07"] = NaN
pct(ts)
pct(ts, skip_all_nans=true)
```

## Options
The TimeSeriesEcon module has global options which are sometimes referenced when invoking methods within
the module. There are currently two options: `:bdaily_creation_bias`, and `:bdaily_holidays_map`.
These can be set and retrieved with the `TimeSeriesEcon.setoption` and `TimeSeriesEcon.getoption` methods.

#### bdaily_creation_bias
This option affects the behavior when creating BDaily MITs from dates which fall on weekends. The default
is `:strict`, which results in errors being thrown when creating BDaily MITs from weekend dates.
Other valid options are: `:previous`, `:next`, and `:nearest`.
```@repl tse
bd"2022-01-01"n # 2022-01-03
TimeSeriesEcon.setoption(:bdaily_creation_bias, :next)
bd"2022-01-01" # 2022-01-03
TimeSeriesEcon.setoption(:bdaily_creation_bias, :strict)
# bd"2022-01-01" # throws an error
```

#### bdaily_holidays_map
This option stores a holidays map for use with some TimeSeriesEcon methods. A holidays map is a `TSeries{BDaily, Bool}` spanning from `bd"1970-01-01"` to `bd"2049-12-31"`, although smaller ranges are allowed. The series is `true` for non-holidays, and `false` for holidays. `cleanedvalues(ts, skip_holidays=true)` will therefore return values for the days where the holidays map is `true`.

There are a number of built-in maps based on the Python [Holidays](https://github.com/dr-prodigy/python-holidays) package. To see the available options, call `TimeSeriesEcon.get_holidays_options()`

```@repl tse
TimeSeriesEcon.get_holidays_options()
```

You can also consult the [documentation](https://python-holidays.readthedocs.io/en/latest/#available-countries) of the Holidays package.

For countries with different regions available, you can also call it with the two-character country code to get the region options.

```@repl tse
TimeSeriesEcon.get_holidays_options("CA")
```

To set the holidays map for a given country/region, use `TimeSeriesEcon.set_holidays_map`:

```@repl tse
TimeSeriesEcon.set_holidays_map("DK") # Denmark
TimeSeriesEcon.set_holidays_map("CA", "ON") # Ontario, Canada
```

!!! note "Good to know"
    The maps may contain errors; they are maintained by a collection of volunteers.
    You can modify them by first setting the map, retrieving it, then setting it manually:
    TimeSeriesEcon.set_holidays_map("DK") # Denmark
    ```@repl tse
    hm = TimeSeriesEcon.getoption(:bdaily_holidays_map)
    for i in 1970:2049
      try
          d = bdaily("$i-05-05")
          hm[d] = false
      catch
      end
    end
    TimeSeriesEcon.setoption(:bdaily_holidays_map, hm)
    ```

The current holidays map can also be unset with this command:

```@repl tse
TimeSeriesEcon.clear_holidays_map()
```

