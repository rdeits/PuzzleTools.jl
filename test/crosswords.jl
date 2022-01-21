using PuzzleTools.Crosswords: LetterMask, exactly_one_bit_set
using Test
using Random

@testset "LetterMask" begin
    for char in 'a':'z'
        @test only(LetterMask(char)) == char
        @test length(LetterMask(char)) == 1
    end

    @test length(LetterMask(0)) == 0
    @test length(LetterMask(1)) == 1
    @test length(LetterMask(2)) == 1
    @test length(LetterMask(4)) == 1
    @test length(LetterMask(5)) == 2
    @test length(LetterMask(typemax(UInt32))) == 32
    @test LetterMask(1) | LetterMask(4) == LetterMask(5)
    @test LetterMask(5) & LetterMask(4) == LetterMask(4)
    @test LetterMask(['a', 'c', 'd']) == LetterMask(1 + 4 + 8)
    @test @inferred(LetterMask(Char[])) == LetterMask(0)
    @test collect(LetterMask(['a', 'b', 'd', 'e'])) == collect("abde")
    @test 'a' ∈ LetterMask('a')
    @test 'b' ∈ LetterMask(collect("abc"))
    @test 'e' ∉ LetterMask(collect("abc"))
    @test 'e' ∉ LetterMask(0)

    Random.seed!(42)
    for i in 1:10000
        mask = LetterMask(rand(UInt))
        @test length(mask) == count(==('1'), bitstring(mask.data))
        @test exactly_one_bit_set(mask) == (length(mask) == 1)
    end
end
