# Tally.jl

*When all you need is just a tally.*

## Status

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://thofma.github.io/Tally.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://thofma.github.io/Tally.jl/dev/)
[![Build Status](https://github.com/thofma/Tally.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/thofma/Tally.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/thofma/Tally.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/thofma/Tally.jl)

## Installation

Since Tally.jl is registered package, it can be installed simply as:
```julia
julia> using Pkg; Pkg.install("Tally")
```

## Usage

### Creating a tally (frequency count)

Given some data stored in an object `data`, one can count the number of occurences of items by calling `tally(data)`:

```julia
julia> T = tally(["x", "x", "y", "x"])
Tally with 4 items in 2 groups:
"x" | 3 | 0.75%
"y" | 1 | 0.25%
```

One can put in any iteratable object

```julia
julia> T = tally(rand(-1:1, 10, 10)) # a random 10x10 matrix with entries in [-1, 1]
Tally with 100 items in 3 groups:
-1 | 37 | 0.37%
0  | 36 | 0.36%
1  | 27 | 0.27%
```

### Plotting a tally

Tally.jl comes with some basic plotting functionalities to plot tallies within the julia REPL:

```julia
julia> T = tally(rand(-1:1, 10, 10))
Tally with 100 items in 3 groups:
1  | 38 | 0.38%
0  | 34 | 0.34%
-1 | 28 | 0.28%

julia> Tally.plot(T)
      ┌                                        ┐
   1  ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 38   0.38%
   0  ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 34       0.34%
   -1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■ 28            0.28%
      └                                        ┘
```

### Plotting a tally using Plots.jl

If you have Plots.jl installed, you can also plot it using this functionality:

```julia
julia> T = tally(rand(-1:1, 10, 10))
Tally with 100 items in 3 groups:
1  | 38 | 0.38%
0  | 34 | 0.34%
-1 | 28 | 0.28%

julia> bar(T, legend = false)
```

This will produce:

<img width="712" alt="ss" src="https://user-images.githubusercontent.com/11231648/204161394-27f392ea-3b97-4626-8b53-e0f506bd4e23.png">

See `?Plots.bar` for more information on how to customize this plot.

## Advanced usage

### Tally is too slow

To work also for objects, for which a consistent hash is not implemented, Tally does not use `hash` by default. This can be enabled using the `use_hash = true` keyword.

```julia
julia> v = [rand([[1], [2]]) for i in 1:100000];

julia> @btime tally($v)
  14.563 ms (100005 allocations: 1.53 MiB)
Tally with 100000 items in 2 groups:
[2] | 50145 | 0.50%
[1] | 49855 | 0.50%

julia> @btime tally($v, use_hash = true)
  2.183 ms (7 allocations: 720 bytes)
Tally with 100000 items in 2 groups:
[2] | 50145 | 0.50%
[1] | 49855 | 0.50%
```

### Advanced counting

When counting, sometimes one wants to only do a tally with respect to some other invariant or with respect to a relation different from `==`. For this task Tally provides the `by` and `equivalence` keyword arguments. Tally will consider two elements `x, y` from the collection equal when counting, whenever `equivalence(by(x), by(y))` is `true`. The default values are `by = identity` and `equivalence = isequal`. If `equivalence` does not define an equivalence relation, the result will be useless. The optional `equivalence` argument is important in case the equivalence relation under consideration does not admit easily computable unique representatives.

Note that to indicate that the counting is non-standard, Tally will print the objects within squarebrakets `[ ]`. 

```julia
julia> v = 1:100000;

julia> tally(v, by = iseven)
Tally with 100000 items in 2 groups:
[2] | 50000 | 0.50%
[1] | 50000 | 0.50%

julia> tally(v, by = x -> mod(x, 3))
Tally with 100000 items in 3 groups:
[1] | 33334 | 0.33%
[3] | 33333 | 0.33%
[2] | 33333 | 0.33%

julia> v = ["abb", "ba", "aa", "ba", "bbba", "aaab"];

julia> tally(v, equivalence = (x, y) -> first(x) == first(y) && last(x) == last(y))
Tally with 6 items in 3 groups:
[ba]  | 3 | 0.50%
[abb] | 2 | 0.33%
[aa]  | 1 | 0.17%
```

