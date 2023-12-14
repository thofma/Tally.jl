![Tally.jl](https://user-images.githubusercontent.com/11231648/204838569-4ad7afcc-5d08-47b4-ac30-3d8d16e975ca.svg)

---

*When all you want is to just tally.*

---

## Status

[![Build Status](https://github.com/thofma/Tally.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/thofma/Tally.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/thofma/Tally.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/thofma/Tally.jl)
[![Pkg Eval](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/T/Tally.svg)](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/report.html)

Table of contents

- [Installation](#nstallation)
- [Usage](#usage)
  - [Creating a tally (frequency count)](#creating-a-tally-frequency-count)
  - [Plotting a tally](#plotting-a-tally)
  - [Prison count](#prison-count)
  - [Tables.jl interface and printing using PrettyTables.jl](#tablesjl-interface-and-printing-using-prettytablejl)
  - [Plotting using Plots.jl](#plotting-a-tally-using-plotsjl)
- [Advanced usage](#advanced-usage)
  - [Tally is too slow](#tally-is-too-slow)
  - [Counting up to an equivalence](#counting-up-to-an-equivalence)
  - [Lazy tallies and animations](#lazy-tallies-and-animations)

## Installation

Since Tally.jl is a registered package, it can be simply installed as follows:
```julia
julia> using Pkg; Pkg.install("Tally")
```

## Usage

### Creating a tally (frequency count)

Given some data stored in an object `data`, one can count the number of occurrences of items by calling `tally(data)`:

```julia
julia> T = tally(["x", "x", "y", "x"])
Tally with 4 items in 2 groups:
x | 3 | 75%
y | 1 | 25%
```

One can put in any iterable object

```julia
julia> T = tally(rand(-1:1, 10, 10)) # a random 10x10 matrix with entries in [-1, 0, 1]
Tally with 100 items in 3 groups:
-1 | 37 | 37%
1  | 32 | 32%
0  | 31 | 31%
```

A tally can be extended by adding more items via `push!` or `append!`.

```julia
julia> push!(T, "x")
Tally with 5 items in 2 groups:
x | 4 | 80%
y | 1 | 20%

julia> append!(T, ["x", "y", "y"])
Tally with 8 items in 2 groups:
x | 5 | 62%
y | 3 | 38%
```

### Plotting a tally

Tally.jl comes with some basic plotting functionalities to plot tallies within the julia REPL:

```julia
julia> T = tally(rand(-1:1, 10, 10))
Tally with 100 items in 3 groups:
0  | 43 | 43%
1  | 33 | 33%
-1 | 24 | 24%

julia> Tally.plot(T)
      ┌                                        ┐
   0  ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 43   43%
   1  ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 33           33%
   -1 ┤■■■■■■■■■■■■■■■■■■■■ 24                   24%
      └                                        ┘
```

See `?Tally.plot` for a list of options on how to customize this plot, which includes giving it a title or choosing a different ordering.

### Prison count

For tallies with counts not too large and pure entertainment, one can also plot tallies using a "prison count":

```julia
julia> T = tally([1, 1, 1, 2, 2, 2, 2, 2, 2, -1]);

julia> prison_count(T)
2  ┃ ┼┼┼┼ │
━━━╋━━━━━━━
1  ┃ │││
━━━╋━━━━━━━
-1 ┃ │
```

### [Tables.jl](https://github.com/JuliaData/Tables.jl) interface and printing using [PrettyTable.jl](https://github.com/ronisbr/PrettyTables.jl)

The objects constructed by Tally.jl implement the [Tables.jl](https://github.com/JuliaData/Tables.jl) interface and thus can be printed using [PrettyTable.jl](https://github.com/ronisbr/PrettyTables.jl):

```julia
julia> T = tally([1, 1, 1, 2, 2, 2, 2, 2, 2, -1]);

julia> pretty_table(T)
┌───────┬────────┐
│  Keys │ Values │
│ Int64 │  Int64 │
├───────┼────────┤
│     2 │      6 │
│     1 │      3 │
│    -1 │      1 │
└───────┴────────┘
```

### Plotting a tally using [Plots.jl](https://github.com/JuliaPlots/Plots.jl)

If you have [Plots.jl](https://github.com/JuliaPlots/Plots.jl) installed and loaded, you can also plot it using this functionality:

```julia
julia> T = tally(rand(-1:1, 10, 10))
Tally with 100 items in 3 groups:
1  | 38 | 38%
0  | 34 | 34%
-1 | 28 | 28%

julia> bar(T, legend = false)
```

This will produce:

<img width="712" alt="ss" src="https://user-images.githubusercontent.com/11231648/204161394-27f392ea-3b97-4626-8b53-e0f506bd4e23.png">

See `?Plots.bar` for more information on how to customize this plot.

## Advanced usage

### Tally is too slow

To work also for objects for which a consistent hash is not implemented, `tally` does not use `hash` by default. This can be enabled using the `use_hash = true` keyword.

```julia
julia> v = [rand([[1], [2]]) for i in 1:100000];

julia> @btime tally($v)
  14.563 ms (100005 allocations: 1.53 MiB)
Tally with 100000 items in 2 groups:
[2] | 50146 | 50.1%
[1] | 49854 | 49.9%

julia> @btime tally($v, use_hash = true)
  2.183 ms (7 allocations: 720 bytes)
Tally with 100000 items in 2 groups:
[2] | 50146 | 50.1%
[1] | 49854 | 49.9%
```

### Counting up to an equivalence

When counting, sometimes one wants to do a tally only with respect to some other invariant or with respect to an equivalence relation different from `==`. For this task `tally` provides the `by` and `equivalence` keyword arguments. The function `tally` will consider two elements `x, y` from the input collection equal when counting, whenever `equivalence(by(x), by(y))` is `true`. The default values are `by = identity` and `equivalence = isequal`. If `equivalence` does not define an equivalence relation, the result will be nonsense. 

Note that to indicate that the counting is non-standard, Tally will print the objects within square brackets `[ ]`. 

```julia
julia> v = 1:100000;

julia> tally(v, by = iseven)
Tally with 100000 items in 2 groups:
[2] | 50000 | 50%
[1] | 50000 | 50%

julia> tally(v, by = x -> mod(x, 3))
Tally with 100000 items in 3 groups:
[1] | 33334 | 33.334%
[3] | 33333 | 33.333%
[2] | 33333 | 33.333%

julia> v = ["abb", "ba", "aa", "ba", "bbba", "aaab"];

julia> tally(v, equivalence = (x, y) -> first(x) == first(y) && last(x) == last(y))
Tally with 6 items in 3 groups:
[ba]  | 3 | 50%
[abb] | 2 | 33%
[aa]  | 1 | 17%
```

The optional `equivalence` argument is important in case the equivalence relation under consideration does not admit easily computable unique representatives. Here is a real world example using `Hecke.jl`, where we only want to count algebraic objects up to isomorphism and thus can make use of the `equivalence` functionality. We make a tally of the 2-parts of the class groups of the first imaginary quadratic number fields:

```julia
julia> using Hecke;

julia> ds = Hecke.squarefree_up_to(1000);

julia> T = tally((class_group(quadratic_field(-d)[1])[1] for d in ds), equivalence = (G, H) -> is_isomorphic(psylow_subgroup(G, 2)[1], psylow_subgroup(H, 2)[1])[1]);

julia> Tally.plot(T)
                          ┌                                        ┐
   [GrpAb: Z/2]           ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 148   24.3%
   [GrpAb: (Z/2)^2]       ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 122         20.1%
   [GrpAb: Z/1]           ┤■■■■■■■■■■■■■■■■■■■■■ 89                  14.6%
   [GrpAb: Z/4]           ┤■■■■■■■■■■■■■■■ 64                        10.5%
   [GrpAb: Z/2 x Z/4]     ┤■■■■■■■■■■■ 48                             7.9%
   [GrpAb: Z/8]           ┤■■■■■■■■■ 39                               6.4%
   [GrpAb: Z/2 x Z/8]     ┤■■■■■■■■ 35                                5.8%
   [GrpAb: (Z/2)^3]       ┤■■■■ 19                                    3.1%
   [GrpAb: (Z/2)^2 x Z/4] ┤■■■■ 18                                    3.0%
   [GrpAb: Z/16]          ┤■■■ 13                                     2.1%
   [GrpAb: Z/32]          ┤■■ 7                                       1.2%
   [GrpAb: Z/2 x Z/16]    ┤■ 5                                        0.8%
   [GrpAb: (Z/2)^2 x Z/8] ┤ 1                                         0.2%
                          └                                        ┘
```

### Lazy tallies and animations

For maximal showoff potential, one can also construct "lazy" tallies, which can be plotted
as an animation.

```julia
julia>T = lazy_tally((rand(-1:1) for i in 1:100));

julia> Tally.animate(T, badges = 4, delay = 0.2, title = "Will 0 win?")
```

will yield

![tally_run2](https://user-images.githubusercontent.com/11231648/205502139-55ca4875-f3ff-429c-af50-5141acb85f5c.svg)

Note that a lazy tally `T` can be converted to an ordinary tally object by invoking `materialize(T)`.
