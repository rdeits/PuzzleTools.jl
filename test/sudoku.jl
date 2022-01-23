using Test
using PuzzleTools.Sudokus

@testset "Hard sudoku example" begin
    # https://www.websudoku.com/?level=3&set_id=2046891460

    puzzle = standard_sudoku();
    state = SudokuState(puzzle)

    fills = """
.6.1395..
...5...67
.5..6....
9..4.....
.71...45.
.....2..8
....2..9.
51...4...
..2691.4."""

    fills = permutedims(reduce(hcat, collect.(split(fills, '\n'))))

    for i in 1:length(fills)
        if fills[i] != '.'
            state.cells[i] = Sudokus.DigitSet(parse(Int, fills[i]))
        end
    end

    expected = [
        2  6  7  1  3  9  5  8  4
        1  9  3  5  4  8  2  6  7
        8  5  4  2  6  7  3  1  9
        9  2  8  4  5  3  1  7  6
        3  7  1  9  8  6  4  5  2
        6  4  5  7  1  2  9  3  8
        4  8  6  3  2  5  7  9  1
        5  1  9  8  7  4  6  2  3
        7  3  2  6  9  1  8  4  5
    ]
    @test only(generate_fills(puzzle, state)) == expected
end
