using Test
using PuzzleTools.TrieIteration
using PuzzleTools.Words: twl06
using DataStructures: Trie, subtrie

@testset "Trie Iteration" begin
    trie = Trie(twl06().sorted_entries)
    for i in 1:5
        prefix = "hello"[1:i]
        @test collect(iterable_keys(subtrie(trie, prefix), prefix)) == keys(subtrie(trie, prefix), prefix)
    end
end
