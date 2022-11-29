![Tally.jl](https://user-images.githubusercontent.com/11231648/204642510-9b255881-6e75-4a78-8eac-b2d77710af18.svg)

---

*When all you want is to just tally.*

---

## Status

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
julia> T = tally(rand(-1:1, 10, 10)) # a random 10x10 matrix with entries in [-1, 0, 1]
Tally with 100 items in 3 groups:
-1 | 37 | 0.37%
0  | 36 | 0.36%
1  | 27 | 0.27%
```

A tally can be extended by adding more items via `push!` or `append!`.

```julia
julia> push!(T, "x")
Tally with 5 items in 2 groups:
x | 4 | 0.80%
y | 1 | 0.20%

julia> append!(T, ["x", "y", "y"])
Tally with 8 items in 2 groups:
x | 5 | 0.62%
y | 3 | 0.38%
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

### Counting up to an equivalence

When counting, sometimes one wants to do a tally only with respect to some other invariant or with respect to a relation different from `==`. For this task Tally provides the `by` and `equivalence` keyword arguments. Tally will consider two elements `x, y` from the input collection equal when counting, whenever `equivalence(by(x), by(y))` is `true`. The default values are `by = identity` and `equivalence = isequal`. If `equivalence` does not define an equivalence relation, the result will be nonsense. The optional `equivalence` argument is important in case the equivalence relation under consideration does not admit easily computable unique representatives.

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

Here is a real world example using `Hecke.jl`, where we only want to count algebraic objects up to isomorphism and thus can make use of the `isequivalence` functionality. We make a tally of the 2-parts of the class group of the first imaginary quadratic number fields:
```
julia> using Hecke;

julia> ds = Hecke.squarefree_up_to(1000);

julia> T = tally((class_group(quadratic_field(-d)[1])[1] for d in ds), equivalence = (G, H) -> is_isomorphic(psylow_subgroup(G, 2)[1], psylow_subgroup(H, 2)[1])[1]);

julia> Tally.plot(T)
                          ┌                                        ┐
   [GrpAb: Z/2]           ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 148   0.243%
   [GrpAb: (Z/2)^2]       ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 122         0.201%
   [GrpAb: Z/1]           ┤■■■■■■■■■■■■■■■■■■■■■ 89                  0.146%
   [GrpAb: Z/4]           ┤■■■■■■■■■■■■■■■ 64                        0.105%
   [GrpAb: Z/2 x Z/4]     ┤■■■■■■■■■■■ 48                            0.079%
   [GrpAb: Z/8]           ┤■■■■■■■■■ 39                              0.064%
   [GrpAb: Z/2 x Z/8]     ┤■■■■■■■■ 35                               0.058%
   [GrpAb: (Z/2)^3]       ┤■■■■ 19                                   0.031%
   [GrpAb: (Z/2)^2 x Z/4] ┤■■■■ 18                                   0.030%
   [GrpAb: Z/16]          ┤■■■ 13                                    0.021%
   [GrpAb: Z/32]          ┤■■ 7                                      0.012%
   [GrpAb: Z/2 x Z/16]    ┤■ 5                                       0.008%
   [GrpAb: (Z/2)^2 x Z/8] ┤ 1                                        0.002%
```
