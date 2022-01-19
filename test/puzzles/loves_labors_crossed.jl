# # https://www.bookspace.world/puzzle/loves-labors-crossed/

# using Test
# using PuzzleTools
# using PuzzleTools: Corpus, is_valid_prefix, entries_with_prefix
# using PuzzleTools.Search: dfs

# @testset "love's labors crossed" begin
#     num(c::Char) = c - 'a' + 1
#     char(n::Integer) = 'a' + n - 1
#     letter_sum_mod(word) = char(mod(sum(num, word), 26))

#     @test letter_sum_mod("cupid") == 'a'

#     function make_grid(corpus::Corpus, dims)
#         function children(state)
#             grid, rows, cols = last(state)
#             grid = copy(grid)

#             Channel{typeof(last(state))}() do channel
#                 if rows > cols
#                     prefix = join(@view(grid[1:rows, cols+1]))
#                     for word in entries_with_prefix(corpus, prefix)
#                         new_sum = letter_sum_mod(word)
#                         sum_ok = true
#                         for i in 1:rows
#                             if new_sum == letter_sum_mod(@view grid[i, :])
#                                 sum_ok = false
#                                 break
#                             end
#                         end
#                         if !sum_ok
#                             continue
#                         end
#                         for i in 1:cols
#                             if new_sum == letter_sum_mod(@view grid[:, i])
#                                 sum_ok = false
#                                 break
#                             end
#                         end
#                         if !sum_ok
#                             continue
#                         end
#                         grid[:, cols + 1] .= codeunits(word)
#                         partials_ok = true
#                         for i in (rows+1):size(grid, 1)
#                             if !is_valid_prefix(corpus, join(@view grid[i, 1:cols+1]))
#                                 partials_ok = false
#                                 break
#                             end
#                         end
#                         if !partials_ok
#                             continue
#                         end
#                         if !is_valid_prefix(corpus, join([letter_sum_mod(@view grid[:, i]) for i in 1:cols + 1]))
#                             continue
#                         end
#                         put!(channel, (copy(grid), rows, cols + 1))
#                     end
#                 else
#                     prefix = join(@view(grid[rows+1, 1:cols]))
#                     for word in entries_with_prefix(corpus, prefix)
#                         new_sum = letter_sum_mod(word)
#                         sum_ok = true
#                         for i in 1:rows
#                             if new_sum == letter_sum_mod(@view grid[i, :])
#                                 sum_ok = false
#                                 break
#                             end
#                         end
#                         if !sum_ok
#                             continue
#                         end
#                         for i in 1:cols
#                             if new_sum == letter_sum_mod(@view grid[:, i])
#                                 sum_ok = false
#                                 break
#                             end
#                         end
#                         if !sum_ok
#                             continue
#                         end
#                         grid[rows + 1, :] .= codeunits(word)
#                         partials_ok = true
#                         for i in (cols+1):size(grid, 2)
#                             if !is_valid_prefix(corpus, join(@view grid[1:rows+1, i]))
#                                 partials_ok = false
#                                 break
#                             end
#                         end
#                         if !partials_ok
#                             continue
#                         end
#                         if !is_valid_prefix(corpus, join([letter_sum_mod(@view grid[i, :]) for i in 1:rows + 1]))
#                             continue
#                         end
#                         put!(channel, (copy(grid), rows + 1, cols))
#                     end
#                 end
#             end
#         end

#         function evaluate(nodes)
#             grid, rows, cols = last(nodes)
#             if (rows, cols) == size(grid)
#                 sums = vcat(letter_sum_mod.(eachrow(grid)),
#                             letter_sum_mod.(eachcol(grid)))
#                 display(sums)
#                 if allunique(sums)
#                     return :good
#                 else
#                     return :bad
#                 end
#             else
#                 return :partial
#             end
#         end

#         start = (fill(' ', dims...), 0, 0)
#         dfs(start, children, evaluate)
#     end

#     dictionary = PuzzleTools.Words.twl06()
#     allowed_words = String[]
#     for word in dictionary
#         if length(word) == 5
#             push!(allowed_words, word)
#             push!(allowed_words, reverse(word))
#         end
#     end

#     corpus = Corpus(allowed_words)

#     result = first(make_grid(corpus, (5, 5)))
#     answer, _ = last(result)
#     display(answer)
#     display(join(permutedims(answer)))
# end
