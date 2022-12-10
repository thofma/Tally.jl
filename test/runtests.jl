using Tally
using Test

using Documenter

if VERSION >= v"1.8"
  DocMeta.setdocmeta!(Tally, :DocTestSetup, :(using Tally); recursive = true)
  doctest(Tally)
end

using Plots

# type with bad hashing

struct A
  x::Int
end

Base.hash(::A) = rand(UInt)

@testset "Tally.jl" begin
  for use_hash in [true, false]
    T = tally([1, 1, 1], use_hash = use_hash)
    @test T.keys == [1]
    @test T.values == [3]

    T = tally([2, 1, 1, 1, 2], use_hash = use_hash)
    @test T.keys == [1, 2]
    @test T.values == [3, 2]

    T = tally([2, 1, -1, 1, -2, 1, -1, 2, 2, 1], use_hash = use_hash)
    @test T.keys == [1, 2, -1, -2]
    @test T.values == [4, 3, 2, 1]

    T = tally([2, 1, -1, 1, -2, 1, -1, 2], equivalence = (x, y) -> abs(x) == abs(y), use_hash = use_hash)
    @test T.keys == [1, 2]
    @test T.values == [5, 3]

    T = tally([2, 1, -1, 1, -2, 1, -1, 2], by = abs, use_hash = use_hash)
    @test T.keys == [1, 2]
    @test T.values == [5, 3]
  end

  # Test the bad type paths
  T = tally((x^2 for x in -1:1 if x > -100))
  @test T.keys == [1, 0]
  @test T.values == [2, 1]

  T = tally((x^2 for x in -1:1 if x > -100), use_hash = true)
  @test T.keys == [1, 0]
  @test T.values == [2, 1]

  T = tally([A(1), A(1), A(2)])
  @test T.keys == [A(1), A(2)]
  @test T.values == [2, 1]

  T = tally([A(1), A(1), A(2)], equivalence = (x, y) -> true)
  @test T.keys == [A(1)]
  @test T.values == [3]

  @test_throws ErrorException show_style(:bla)

  T = tally([2, 1, 1, 1, 1, 2, 2, 3])
  @test sprint(show, "text/plain", T) isa String
  @test sprint(show, T) isa String
  prison_count(T)

  T = tally([2, 1, 1, 1, 1, 2, 2, 3], by = x -> x^2)
  s = sprint(show, "text/plain", T)
  @test occursin("[1]", s)
  prison_count(T)
  show_style(:prison)
  s = sprint(show, "text/plain", T)
  @test occursin("│", s)
  show_style(:table)


  T = tally([2, 1, 1, 1, 1, 2, 2, 3], equivalence = (x, y) -> x == y)
  s = sprint(show, "text/plain", T)
  @test occursin("[1]", s)
  prison_count(T)
  show_style(:prison)
  s = sprint(show, "text/plain", T)
  @test occursin("│", s)
  show_style(:table)

  T = tally(Int[])
  @test sprint(show, "text/plain", T) isa String
  @test sprint(show, T) isa String
  prison_count(T)
  show_style(:prison)
  s = sprint(show, "text/plain", T)
  show_style(:table)

  T = tally(push!([1 for i in 1:100000], 2))
  s = sprint(show, "text/plain", T)
  @test occursin("1", s)
  show_style(:prison)
  s = sprint(show, "text/plain", T)
  @test occursin("│", s)
  show_style(:table)

  T = tally(append!([1 for i in 1:100000], [2 for i in 1:100001]))
  s = sprint(show, "text/plain", T)
  @test occursin("1", s)
  show_style(:prison)
  s = sprint(show, "text/plain", T)
  @test occursin("│", s)
  show_style(:table)

  # unicode plotting

  # decimals are different on julia 1.0
  if VERSION >= v"1.8"
    T = tally([2, 1, 1, 1, 1, 2, 2, 3])
    plot1 =
    "     ┌                                        ┐    \n" *
    "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 4   50%\n" *
    "   2 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 3            38%\n" *
    "   3 ┤■■■■■■■■■ 1                               12%\n" *
    "     └                                        ┘    "

    plot2 =
    "     ┌                                        ┐    \n" *
    "   3 ┤■■■■■■■■■ 1                               12%\n" *
    "   2 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 3            38%\n" *
    "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 4   50%\n" *
    "     └                                        ┘    "

    plot3 =
    "     ┌                                        ┐    \n" *
    "   2 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 3            38%\n" *
    "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 4   50%\n" *
    "   3 ┤■■■■■■■■■ 1                               12%\n" *
    "     └                                        ┘    "

    plot4 =
    "     ┌                                        ┐    \n" *
    "   3 ┤■■■■■■■■■ 1                               12%\n" *
    "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 4   50%\n" *
    "   2 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 3            38%\n" *
    "     └                                        ┘    "

    plot5 =
    "     ┌                                        ┐    \n" *
    "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 4   50%\n" *
    "   2 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 3            38%\n" *
    "   3 ┤■■■■■■■■■ 1                               12%\n" *
    "     └                                        ┘      "

    plot6 =
    "     ┌                                        ┐ \n" *
    "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 4   \n" *
    "   2 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 3            \n" *
    "   3 ┤■■■■■■■■■ 1                               \n" *
    "     └                                        ┘ "

    plot7 =
    "                        Tally                      \n" *
    "     ┌                                        ┐    \n" *
    "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 4   50%\n" *
    "   2 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 3            38%\n" *
    "   3 ┤■■■■■■■■■ 1                               12%\n" *
    "     └                                        ┘    "

    plot8 =
    "     ┌                                        ┐       \n" *
    "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 10 000   99.99%\n" *
    "   2 ┤ 1                                         0.01%\n" *
    "     └                                        ┘       "

    @test string(Tally.plot(T)) == plot1
    show_style(:plot)
    s = sprint(show, "text/plain", T)
    @test s == plot1
    show_style(:table)

    @test string(Tally.plot(T, sortby = :value)) == plot1
    @test string(Tally.plot(T, sortby = :key)) == plot2
    @test string(Tally.plot(T, sortby = :key, reverse = true)) == plot1
    @test string(Tally.plot(T, sortby = :value, reverse = true)) == plot2
    @test string(Tally.plot(T, sortby = x -> sin(x))) == plot3
    @test string(Tally.plot(T, sortby = x -> sin(x), reverse = true)) == plot4
    @test string(Tally.plot(T, percentage = false)) == plot6
    @test string(Tally.plot(T, title = "Tally")) == plot7

    @test bar(T) isa Plots.Plot

    T = tally(Int[])
    Tally.plot(T)

    # Distorted percentages

    T = tally(push!([1 for i in 1:10_000], 2))
    @test T.keys == [1, 2]
    @test T.values == [10_000, 1]
    @test string(Tally.plot(T)) == plot8
  end

  # Iteration and pushing

  T = tally([2, 1, 1, 1, 2])
  @test collect(T) == [1 => 3, 2 => 2]
  push!(T, 2)
  push!(T, 2)
  @test T.keys == [2, 1]
  @test T.values == [4, 3]
  @test T[1] == 3
  @test get(T, 3, 5) == 5
  @test_throws KeyError T[3]

  T = tally([2, 1, 1, 1, 2])
  append!(T, [2, 1, 2, 2])
  @test T.keys == [2, 1]
  @test T.values == [5, 4]

  T = tally([-1, 1, 2, 1, -1], equivalence = (x, y) -> abs(x) == abs(y))
  @test T.keys == [-1, 2]
  @test T.values == [4, 1]
  push!(T, -2)
  @test T.keys == [-1, 2]
  @test T.values == [4, 2]
  append!(T, [2, -2, 2])
  @test T.keys == [2, -1]
  @test T.values == [5, 4]
  @test T[2] == 5
  @test T[-2] == 5
  @test_throws KeyError T[3]
  @test get(T, 3, 5) == 5

  # lazy tally
  T = lazy_tally((rand(-1:1) for i in 1:100))
  Tally.animate(T, delay = 0.001, badges = 10)
  println()
  @test sprint(show, "text/plain", T) isa String
  @test sprint(show, T) isa String
  @test  materialize(T) isa Tally.TallyT

  @testset "Arithmetic" begin
    T1 = tally([2, 1, 1, 1, 2])
    T2 = tally([2, 2, 1, 1, 2])
    @test T1 + T2 == tally([1, 1, 1, 1, 1, 2, 2, 2, 2, 2])
    @test T1 - T1 == Tally.TallyT(Int[], Int[])
    @test T1 - T2 == Tally.TallyT([1, 2], [1, -1])

    T1 = tally([1, 1, 2])
    T2 = tally([2, 3, 3])
    @test T1 + T2 == tally([1, 1, 2, 2, 3, 3])
    @test (T1 + T2) - T1 == T2

    T1 = tally([], by = sin)
    T2 = tally([])
    @test_throws ErrorException T1 + T2
    @test_throws ErrorException T1 - T2
  end
end
