module Tally

import Printf: @sprintf

import UnicodePlots: barplot, label!

import RecipesBase

export tally, lazy_tally, materialize

################################################################################
#
#  Type
#
################################################################################

mutable struct TallyT{T} <: AbstractDict{T, Int}
  keys::Vector{T}
  values::Vector{Int}
  by
  equivalence

  function TallyT(keys::Vector{T}, values::Vector{Int}, by = isequal, equivalence = identity) where {T}
    p = sortperm(values, rev = true)
    return new{T}(keys[p], values[p], by, equivalence)
  end
end

mutable struct LazyTallyT{T}
  it::T
  by
  equivalence

  LazyTallyT(it::T, by, equivalence) where {T} = new{T}(it, by, equivalence)
end

################################################################################
#
#  Helper
#
################################################################################

# helper function to create the right dictionary
function _create_dict(it::T) where {T}
  if Base.IteratorEltype(it) == Base.HasEltype()
    S = eltype(T)
    return Dict{S, Int}()
  else
    return Dict{Any, Int}()
  end
end

# D is a Vector{<:Pair}
function _has_key(x, K::Vector, by, equivalence)
  i = findfirst(K) do y
    return equivalence(by(x), by(y))
  end
  if i !== nothing
    return true, i
  else
    return false, 0
  end
end

# For when we cannot or don't want to go via
# dictionaries
function _tally_generic(it::T, by, equivalence) where {T}
  if Base.IteratorEltype(it) == Base.HasEltype()
    # if it has an element type, use it
    S = eltype(T)
    K = Vector{S}()
    V = Vector{Int}()
  else
    # do whatever you wan
    K = Vector{Any}()
    V = Vector{Int}()
  end
  t = TallyT(K, V, by, equivalence)
  append!(t, it)
  return t
end

function _tally_dict(it)
  D = _create_dict(it)
  for x in it
    # double lookup, but we do not care about speed
    k = get!(D, x, 0)
    D[x] = k + 1
  end
  return TallyT(collect(keys(D)), collect(values(D)))
end

"""
    tally(data; kw...)

Construct a tally by considering all elements of `data`, which can be any
iteratable object.

# Keyword arguments
- `by`: By default, elements themselves are compared when doing the counting. If `by = f` is provided, than the elements `(f(k) for k in it)` will be counted.
- `equivalence`: By default, elements are compared using the `isequal` function. This can be overwritten by providing a 2-ary boolean function `equivalence`.
- `use_hash`: Enable the use of hashing. This assumes that the elements that are counted have a consistent `hash` implementation. Use this if you want the function to go faster.

# Examples

```jldoctest
julia> T = tally([1, 1, 1, -1, -1, 2, 2, 3])
Tally with 8 items in 4 groups:
1  | 3 | 0.38%
2  | 2 | 0.25%
-1 | 2 | 0.25%
3  | 1 | 0.12%

julia> T = tally([1, 1, 1, -1, -1, 2, 2, 3], by = abs)
Tally with 8 items in 3 groups:
[1] | 5 | 0.62%
[2] | 2 | 0.25%
[3] | 1 | 0.12%

julia> T = tally([1, 1, 1, -1, -1, 2, 2, 3], equivalence = (x, y) -> x^2 == y^2)

Tally with 8 items in 3 groups:
[1] | 5 | 0.62%
[2] | 2 | 0.25%
[3] | 1 | 0.12%
"""
function tally(it; by = identity, equivalence = isequal, use_hash::Bool = false)
  if by === identity && equivalence === isequal && use_hash
    return _tally_dict(it)
  else
    return _tally_generic(it, by, equivalence)
  end
end

"""
    lazy_tally(it; kw...)

Turns the iterable object `it` into a lazy tally. The only purpose is to feed
it to the `animate` function.

It can be materialized into a proper tally by calling `materialize`.

For the keyword arguments see `tally`.
"""
lazy_tally(it; by = identity, equivalence = isequal) = LazyTallyT(it, identity, equivalence)

function materialize(T::LazyTallyT)
  _T = TallyT(Vector{Any}(), Vector{Int}(), T.by, T.equivalence)
  append!(_T, T.it)
  return _T
end

################################################################################
#
#  Printing
#
################################################################################

# a helper
# I'm sorry
sprint_formatted(fmt, args...) = @eval @sprintf($fmt, $(args...))

# print pairs with Any nicer, because the following is nonsense
# julia> Pair{Any, Any}(1, 2)
# Pair{Any, Any}(1, 2)
_print_pair(io, x) = print(io, x[1], " => ", x[2])

function _maximal_length_of_items(keys, vals)
  cnt_name = 0
  cnt_digits = 0
  for x in zip(keys, vals)
    cnt_name = max(cnt_name, length((x[1])))
    cnt_digits = max(cnt_digits, ndigits(x[2]))
  end
  return cnt_name, cnt_digits
end

function _get_nice_percentages(per::Vector{Float64})
  find_ndigits = 0
  nice = String[]
  if length(per) == 0
    return 0, String[]
  end
  while true
    for p in per
      iszero(p) && continue
      while all(x -> x in [' ', '0', '.'], sprint_formatted("%3.$(find_ndigits)f", p))
        find_ndigits += 1
      end
    end
    nice = [lpad(sprint_formatted("%3.$(find_ndigits)f", p), find_ndigits + 4)* "%" for p in per]

    # now check if different values are distinguished
    good = true
    for i in 1:length(per)
      if any(j -> per[i] != per[j] && nice[i] == nice[j], 1:length(per))
        find_ndigits += 1
        good = false
        break
      end
    end
    if good
      break
    end
  end

  while all(x -> startswith(x, ' '), nice)
    nice = map(x -> x[2:end], nice)
  end

  return find_ndigits, nice
end

# Print it as a table
function Base.show(io::IO, ::MIME"text/plain", T::TallyT)
  first = true
  n = sum(T.values, init = 0)
  k, v = _prepare_for_plot(T)
  print(io, "Tally with $n items in $(length(T.keys)) groups")
  if length(T) == 0
    return
  end
  print(io, ":")
  l_names, l_digits = _maximal_length_of_items(k, v)
  percentages = [100 * x/n for x in v]
  find_ndigits, percentage_strings = _get_nice_percentages(percentages)
  for (i, x) in enumerate(zip(k, v))
    println(io)
    print(io, rpad(x[1], l_names))
    print(io, " | ")
    print(io, lpad(sprint(show, x[2]), l_digits))
    print(io, " | ")
    print(io, percentage_strings[i])
  end
end

# Print it inline
function Base.show(io::IO, T::TallyT)
  print(io, "Tally(")
  first = true
  for x in T
    if first
      _print_pair(io, x)
      first = false
    else
      print(io, ", ")
      _print_pair(io, x)
    end
  end
  print(io, ")")
end

function Base.show(io::IO, T::LazyTallyT)
  print(io, "Lazy tally")
end

################################################################################
#
#  Iteration and other stuff
#
################################################################################

Base.keys(T::TallyT) = T.keys

Base.values(T::TallyT) = T.values

Base.eltype(::Type{TallyT{T}}) where {T} = Pair{T, Int}

Base.length(T::TallyT) = length(T.keys)

function Base.iterate(T::TallyT, st = 1)
  return (st > length(T) ? nothing : (T.keys[st] => T.values[st], st + 1))
end

function _push!(T::TallyT, x)
  K = T.keys
  V = T.values
  fl, j = _has_key(x, K, T.by, T.equivalence)
  if fl
    V[j] = V[j] + 1
  else
    push!(K, x)
    push!(V, 1)
  end
  return T
end

function Base.sort!(T::TallyT; rev = true, kwargs...)
  p = sortperm(T.values; rev, kwargs...)
  permute!(T.keys, p)
  permute!(T.values, p)
  return T
end

function Base.push!(T::TallyT, x)
  _push!(T, x)
  sort!(T)
  return T
end

function Base.append!(T::TallyT, it)
  for x in it
    _push!(T, x)
  end
  sort!(T)
  return T
end

function Base.get(T::TallyT, key, default)
  ind = findfirst(==(key), T.keys)
  if ind === nothing
    return default
  else
    return T.values[ind]
  end
end

function Base.:+(T1::TallyT, T2::TallyT)
  return TallyT(keys(T1), [T1.values[i] + T2[key] for (i, key) in enumerate(keys(T1))])
end


function Base.:-(T1::TallyT, T2::TallyT)
  return TallyT(keys(T1), [T1.values[i] - T2[key] for (i, key) in enumerate(keys(T1))])
end

################################################################################
#
#  Plotting
#
################################################################################

# We wantleft alignment for unicode plots
function _pad_the_labels(keys)
  l = 0
  for k in keys
    l = max(l, length(k))
  end
  res = []
  for k in keys
    push!(res, rpad(k, l))
  end
  return res
end

# Plotting packages want the labels and the values
function _prepare_for_plot(T::TallyT; sortby = :value, reverse = false, title = "Tally")
  keys = []
  vals = Int[]
  percentage = Float64[]
  n = sum(T.values, init = 0)
  for x in T
    push!(keys, x[1])
    push!(vals, x[2])
    push!(percentage, 100 * x[2]/n)
  end
  if isempty(T)
    return keys, vals, percentage
  end

  KT = typeof(keys[1])
  KV = typeof(vals[1])
  if sortby === :key && hasmethod(isless, (KT, KT))
    p = sortperm(keys)
    keys = keys[p]
    vals = vals[p]
    percentage = percentage[p]
  elseif sortby === :value && hasmethod(isless, (KV, KV))
    p = sortperm(vals)
    keys = keys[p]
    vals = vals[p]
    percentage = percentage[p]
  elseif hasmethod(isless, (KT, KT))
    p = sortperm(keys, by = sortby)
    keys = keys[p]
    vals = vals[p]
    percentage = percentage[p]
  end

  if !reverse
    reverse!(keys)
    reverse!(vals)
    reverse!(percentage)
  end

  if T.by !== identity || T.equivalence !== isequal
    keys = ["[" * string(k) * "]" for k in keys]
  else
    keys = [string(k) for k in keys]
  end

  return keys, vals, percentage
end

"""
    Tally.plot(T::TallyT; kw...)

Plot the tally `T` using unicode plots.

# Keyword arguments
- `sortby`: If `sortby = :key`, the data will be sorted by the keys and similar
  for `sortby = :value`. If `sortby` is anything else, keys will be sorted via
  the `sort` function with `by = sortby` argument.  - `percentage::Bool`: Display
  percentages or not.
- `reverse::Bool`: Reverse the order.
- `title::String`: A title for the plot.
"""
function plot(T::TallyT; sortby = :value, percentage = true, reverse = false, title = "")
  show_percentage = percentage

  keys, vals, percentage = _prepare_for_plot(T, sortby = sortby, reverse =reverse)

  _, percentage = _get_nice_percentages(percentage)

  if length(T) == 0
    print("No plot for empty tallies.")
    return
  end

  P = barplot(_pad_the_labels(keys), vals, title = title)

  if show_percentage
    for i in 1:length(percentage)
      label!(P, :r, i, percentage[i])
    end
  end
  return P
end

RecipesBase.@recipe f(::Type{Tally.TallyT{S}}, T::Tally.TallyT{S}) where {S} = begin x, y = Tally._prepare_for_plot(T); return collect(zip(string.(x), y)) end

# dynamic plot

function _dynamic_plot(it, by, equivalence; sortby = :value, percentage = true, reverse = false, title = "", delay = 0.1, badges = 1)
  _T = TallyT(Vector{Any}(), Vector{Int}(), by, equivalence)
  for (i, x) in enumerate(it)
    push!(_T, x)
    print("\033[2J")
    print("\033[H")
    if i % badges == 0
      print(plot(_T, sortby = sortby, percentage = percentage, reverse = reverse, title = title))
    #println("\033[2J")
      sleep(delay)
    end
  end
end

"""
    animate(T::LazyTally; badges = 1, delay = 0.1, kw...)

Plots the lazy tally continously by adding `badges` many elements after each
plot with a delay of `delay` seconds between the plots. The other keyword
arguments are as for `Tally.plot`.
"""
function animate(T::LazyTallyT; sortby = :value, percentage = true, reverse = false, title = "", delay = 0.1, badges = 1)
  return _dynamic_plot(T.it, T.by, T.equivalence, delay = delay, badges = badges, title = title)
end

end
