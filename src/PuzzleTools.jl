module PuzzleTools

include("corpus.jl")
include("words.jl")
include("caching.jl")
include("wiki.jl")
include("search.jl")
include("trie_iteration.jl")
include("bitsets.jl")

function generate_fills end

include("crosswords.jl")
include("sudoku.jl")

end
