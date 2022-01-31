using Test
using PuzzleTools.Search: dfs
using PuzzleTools.Words
using Graphs: SimpleDiGraph, add_edge!
using PuzzleTools: is_valid_prefix

@testset "graph_search" begin
    actions = Dict(
        1 => [11, 22, 9],
        2 => [6, 14, 12, 9, 5, 1],
        3 => [1, 6, 8, 20, 22],
        4 => [24, 20, 3, 11],
        5 => [2, 1, 6],
        6 => [2, 18, 17],
        7 => [24, 1, 10, 12, 2],
        8 => [3, 14, 6, 1],
        9 => [3, 21, 10, 2, 18, 1],
        10 => [16, 18, 6, 9],
        11 => [24, 17, 21, 4],
        12 => [5, 23, 17, 19],
        13 => [20, 1, 22, 14],
        14 => [10, 15, 7, 8],
        15 => [1, 18, 19, 12],
        16 => [1, 6, 5, 10, 2],
        17 => [19, 1, 3],
        18 => [20, 1, 19, 6],
        19 => [21, 2, 15, 12, 6],
        20 => [1, 21, 15, 23],
        21 => [19, 20, 3, 14, 22],
        22 => [15, 21, 6, 2, 20, 13, 14],
        23 => [10, 19, 1, 12, 22, 6],
        24 => []
    )

    graph = SimpleDiGraph(24)
    for (a, dests) in actions
        for b in dests
            add_edge!(graph, a, b)
        end
    end
    evaluate = path -> length(path) == 24 ? :good : :partial
    @test only(dfs(graph, 1, evaluate; allow_cycles=false)) == [1, 11, 4, 3, 8, 6, 17, 19, 15, 12, 23, 10, 16, 5, 2, 9, 18, 20, 21, 22, 13, 14, 7, 24]
end

@testset "dictionary search" begin
    # Run a depth-first search over strings, and make sure the result is exactly the same as the corpus itself

    text = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum"""
    corpus = sort(unique(split(replace(lowercase(text), r"[^a-z]" => ""))))

    children(path) = 'a':'z'

    function evaluate(path)
        if join(@view path[2:end]) in corpus
            return :good_and_partial
        elseif is_valid_prefix(corpus, join(@view path[2:end]))
            return :partial
        else
            return :bad
        end
    end

    search = dfs(Char(0), children, evaluate)
    @test [join(w[2:end]) for w in search] == corpus
end
