using Test
using PuzzleTools
using PuzzleTools.Crosswords: block_crossword, generate_fills
using PuzzleTools.Words: twl06

@testset "love's labors crossed" begin
    num(c::Char) = c - 'a' + 1
    char(n::Integer) = 'a' + n - 1
    letter_sum_mod(word) = char(mod(sum(num, word), 26))

    corpus = String[]
    for word in twl06()
        if length(word) == 5
            push!(corpus, word)
            push!(corpus, reverse(word))
            push!(corpus, string(word, letter_sum_mod(word)))
            push!(corpus, string(reverse(word), letter_sum_mod(word)))
        end
    end

    cells = fill(true, 6, 6)
    cells[6, 6] = false
    puzzle = block_crossword(cells)

    for solution in Iterators.take(generate_fills(puzzle, corpus), 5)
        state = last(solution)
        letters = only.(state.cells)
        display(reshape(vcat(letters, '~'), 6, :))
        display(join(permutedims(reshape(vcat(letters, '~'), 6, :)[1:5, 1:5])))
#         break
    end
end
