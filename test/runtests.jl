include("caching.jl")
include("corpus.jl")
include("crosswords.jl")
include("search.jl")
include("trie_iteration.jl")
include("wiki.jl")
include("words.jl")

const PUZZLES_FOLDER = "puzzles"

for file in Base.Filesystem.readdir(PUZZLES_FOLDER)
    if endswith(file, ".jl")
        include(joinpath(PUZZLES_FOLDER, file))
    end
end
