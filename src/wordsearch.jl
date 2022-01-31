module WordSearch

using ..PuzzleTools.Search: dfs
using ..PuzzleTools: is_valid_prefix, Corpus
using Graphs: AbstractGraph, vertices

function boggle(graph::AbstractGraph, letters::AbstractVector{Char}, corpus::Corpus;
        min_length=3, max_length=Inf)
    function evaluate(path)
        candidate = join(getindex.(Ref(letters), path))
        if length(path) >= min_length && candidate in corpus
            :good_and_partial
        elseif is_valid_prefix(corpus, candidate) && length(path) < max_length
            :partial
        else
            :bad
        end
    end

    results = collect(Iterators.map(Iterators.flatten(
            (dfs(graph, i, evaluate; allow_cycles=false) for i in vertices(graph)))) do path
        join(getindex.(Ref(letters), path))
    end)

    sort!(results, by=length, rev=true)
    results
end

end
