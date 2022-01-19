using Test
using PuzzleTools.Words: sowpods, UKACD

@testset "Words" begin
    @test "aaronsbeard" in UKACD()
    @test "aaronsbeard" ∉ sowpods()
end
