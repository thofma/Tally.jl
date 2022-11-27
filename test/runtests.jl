using Tally
using Test

using Plots

@testset "Tally.jl" begin
  for use_hash in [true, false]
    T = tally([1, 1, 1], use_hash = use_hash)
    @test T.data == [(1 => 3)]

    T = tally([2, 1, 1, 1, 2], use_hash = use_hash)
    @test T.data == [(1 => 3), (2 => 2)]

    T = tally([2, 1, -1, 1, -2, 1, -1, 2, 2, 1], use_hash = use_hash)
    @test T.data == [(1 => 4), (2 => 3), (-1 => 2), (-2 => 1)]

    T = tally([2, 1, -1, 1, -2, 1, -1, 2], by = (x, y) -> abs(x) == abs(y), use_hash = use_hash)
    @test T.data == [(1 => 5), (2 => 3)]
  end

  # type with bad hashing

  struct A
    x::Int
  end

  Base.hash(::A) = rand(UInt)

  T = tally([A(1), A(1), A(2)], use_hash = false)
  @test T.data == [A(1) => 2, A(2) => 1]

  T = tally([A(1), A(1), A(2)], use_hash = false, by = (x, y) -> true)
  @test T.data == [A(1) => 3]

  # unicode plotting

  T = tally([2, 1, 1, 1, 1, 2, 2, 3])
  plot1 = 
  "     ┌                                        ┐        \n" *
  "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 4   0.50  %\n" *
  "   2 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 3            0.38  %\n" *
  "   3 ┤■■■■■■■■■ 1                               0.12  %\n" *
  "     └                                        ┘        "

  plot2 =
  "     ┌                                        ┐        \n" *
  "   3 ┤■■■■■■■■■ 1                               0.12  %\n" *
  "   2 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 3            0.38  %\n" *
  "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 4   0.50  %\n" *
  "     └                                        ┘        "

  plot3 =
  "     ┌                                        ┐        \n" *
  "   2 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 3            0.38  %\n" *
  "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 4   0.50  %\n" *
  "   3 ┤■■■■■■■■■ 1                               0.12  %\n" *
  "     └                                        ┘        "

  plot4 =
  "     ┌                                        ┐        \n" *
  "   3 ┤■■■■■■■■■ 1                               0.12  %\n" *
  "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 4   0.50  %\n" *
  "   2 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 3            0.38  %\n" *
  "     └                                        ┘        "

  plot5 = 
  "     ┌                                        ┐        \n" *
  "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 4   0.50  %\n" *
  "   2 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 3            0.38  %\n" *
  "   3 ┤■■■■■■■■■ 1                               0.12  %\n" *
  "     └                                        ┘        "
  
  plot6 =
  "     ┌                                        ┐ \n" *
  "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 4   \n" *
  "   2 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 3            \n" *
  "   3 ┤■■■■■■■■■ 1                               \n" *
  "     └                                        ┘ "

  plot7 = 
  "                        Tally                          \n" *
  "     ┌                                        ┐        \n" *
  "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 4   0.50  %\n" *
  "   2 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 3            0.38  %\n" *
  "   3 ┤■■■■■■■■■ 1                               0.12  %\n" *
  "     └                                        ┘        "
  @test string(Tally.plot(T)) == plot1
  @test string(Tally.plot(T, sortby = :value)) == plot1
  @test string(Tally.plot(T, sortby = :key)) == plot2
  @test string(Tally.plot(T, sortby = :key, reverse = true)) == plot1
  @test string(Tally.plot(T, sortby = :value, reverse = true)) == plot2
  @test string(Tally.plot(T, sortby = x -> sin(x))) == plot3
  @test string(Tally.plot(T, sortby = x -> sin(x), reverse = true)) == plot4
  @test string(Tally.plot(T, percentage = false)) == plot6
  @test string(Tally.plot(T, title = "Tally")) == plot7

  @test bar(T) isa Plots.Plot

  # Distorted percentages

  T = tally(push!([1 for i in 1:10000], 2))
  @test T.data == [(1 => 10000), (2 => 1)]

  plot8 =
  "     ┌                                        ┐          \n" *
  "   1 ┤■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 10 000   0.9999  %\n" *
  "   2 ┤ 1                                        0.0001  %\n" *
  "     └                                        ┘          "

  @test string(Tally.plot(T)) == plot8

  # Iteration and pushing

  T = tally([2, 1, 1, 1, 2])
  @test collect(T) == T.data
  push!(T, 2)
  push!(T, 2)
  @test T.data == [(2 => 4), (1 => 3)]

  T = tally([2, 1, 1, 1, 2])
  append!(T, [2, 1, 2, 2])
  @test T.data == [(2 => 5), (1 => 4)]

  T = tally([-1, 1, 2, 1, -1], by = (x, y) -> abs(x) == abs(y))
  @test T.data == [(-1 => 4), (2 => 1)]
  push!(T, -2)
  @test T.data == [(-1 => 4), (2 => 2)]
  append!(T, [2, -2, 2])
  @test T.data == [(2 => 5), (-1 => 4)]
end