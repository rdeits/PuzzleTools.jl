using PuzzleTools.Crosswords
using PuzzleTools.Bitsets: data
using PuzzleTools.Crosswords: LetterSet, exactly_one_element
using PuzzleTools.Words: twl06
using Test
using Random

@testset "LetterSet" begin
    for char in 'a':'z'
        @test only(LetterSet(char)) == char
        @test length(LetterSet(char)) == 1
    end

    @test length(LetterSet()) == 0
    @test length(LetterSet('a')) == 1
    @test length(LetterSet(['a', 'b'])) == 2
    @test length(LetterSet('c')) == 1
    @test length(LetterSet(['c', 'a'])) == 2
    @test length(LetterSet('a':'z')) == 26
    @test LetterSet('a') ∪ LetterSet('d') == LetterSet(['d', 'a'])
    @test LetterSet(['d', 'a']) ∩ LetterSet('d') == LetterSet('d')
    @test data(LetterSet(['a', 'c', 'd'])) == 1 + 4 + 8
    @test @inferred(LetterSet(Char[])) == LetterSet()
    @test collect(LetterSet(['a', 'b', 'd', 'e'])) == collect("abde")
    @test 'a' ∈ LetterSet('a')
    @test 'b' ∈ LetterSet(collect("abc"))
    @test 'e' ∉ LetterSet(collect("abc"))
    @test 'e' ∉ LetterSet()

    Random.seed!(42)
    for i in 1:10000
        mask = LetterSet(rand(UInt32))
        @test length(mask) == count(==('1'), bitstring(mask.data))
        @test exactly_one_element(mask) == (length(mask) == 1)
    end
end

@testset "Small Block Grids" begin
    @testset "$N x $N" for N in [3, 4, 5, 6]
        corpus = twl06()
        grid = ones(Bool, N, N)
        puzzle = block_crossword(grid)
        result = first(generate_fills(puzzle, corpus))
        filled_grid = reshape(result, size(grid))
        for row in eachrow(filled_grid)
            @test join(row) in corpus
        end
        for col in eachcol(filled_grid)
            @test join(col) in corpus
        end

        all_entries = [join(x) for x in Iterators.flatten((eachrow(filled_grid), eachcol(filled_grid)))]
        @test allunique(all_entries)
    end
end

@testset "Block crossword entries" begin
    corpus = twl06()
    N = 5
    grid = ones(Bool, N, N)
    grid[1:2, 1:2] .= false
    grid[5, 5] = false
    puzzle = block_crossword(grid)
    result = first(generate_fills(puzzle, corpus))
    filled_grid = reshape(result, N, N)
    for i in 1:length(filled_grid)
        if !grid[i]
            @test filled_grid[i] == '█'
        else
            @test filled_grid[i] in 'a':'z'
        end
    end

    expected_entries = [(1, 3:5), (:, 3), (:, 4), (1:4, 5),
        (2, 3:5), (3, :), (3:5, 1), (3:5, 2), (4, :), (5, 1:4)]
    for (i, expected_entry) in enumerate(expected_entries)
        expected_cell_indices = view(reshape(1:length(grid), size(grid)), expected_entry...)
        @test puzzle.entries[i] == expected_cell_indices
        @test join(view(filled_grid, expected_entry...)) in corpus
    end
    all_entries = [join(view(filled_grid, e)) for e in puzzle.entries]
    @test allunique(all_entries)
end

@testset "Full size crossword" begin
    corpus = twl06()
    grid = ones(Bool, 15, 15)
    grid[1:3, 7] .= false
    grid[1:2, 11] .= false
    grid[4, 5] = false
    grid[4, 10] = false
    grid[5, 1:3] .= false
    grid[5, 8] = false
    grid[6, 13:15] .= false
    grid[7, 6:7] .= false
    grid[8, 4] = false
    grid[9, 5] = false
    grid[10, 1:3] .= false

    grid .= grid .&& rot180(grid)

    puzzle = block_crossword(grid)
    result = first(generate_fills(puzzle, corpus))
    filled_grid = reshape(result, 15, 15)
    for entry in puzzle.entries
        @test join(view(filled_grid, entry)) in corpus
    end
    all_entries = [join(view(filled_grid, e)) for e in puzzle.entries]
    @test allunique(all_entries)
end
