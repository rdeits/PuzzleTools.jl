using Test
using PuzzleTools
using PuzzleTools.Crosswords: block_crossword, generate_fills, GridState, CellState
using PuzzleTools.Words: twl06

@testset "love's labors crossed" begin
    # Note: This test uses N = 4, while the original puzzle would use N = 5. Using a smaller N here keeps the test efficient while still exercising the right code.
    N = 4

    num(c::Char) = c - 'a' + 1
    char(n::Integer) = 'a' + n - 1
    letter_sum_mod(word) = char(mod(sum(num, word), 26))

    corpus = String[]
    for word in twl06()
        if length(word) == N
            if length(unique(word)) == N
                push!(corpus, word)
                push!(corpus, reverse(word))
            end
            push!(corpus, string(word, letter_sum_mod(word)))
            push!(corpus, string(reverse(word), letter_sum_mod(word)))
        end
    end

    cells = fill(true, N + 1, N + 1)
    cells[N + 1, N + 1] = false
    puzzle = block_crossword(cells)

    initial_state = GridState(puzzle, corpus)
    I = LinearIndices((N + 1, N + 1))
    for i in 1:N
        initial_state.cells[I[N + 1, i]] = CellState('a':'l')
    end
    for i in 1:N
        initial_state.cells[I[i, N + 1]] = CellState('m':'z')
    end

    solution = first(generate_fills(puzzle, initial_state))
    filled_grid = reshape(solution, N + 1, N + 1)

    for row in 1:N
        @test join(filled_grid[row, :]) in corpus
    end
    @test join(filled_grid[end, 1:N]) in corpus
    for col in 1:N
        @test join(filled_grid[:, col]) in corpus
    end
    @test join(filled_grid[1:N, end]) in corpus
    @test length(unique(vcat(filled_grid[end, 1:N], filled_grid[1:N, end]))) == 2N
end
