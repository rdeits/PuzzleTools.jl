include("corpus.jl")
include("words.jl")
include("caching.jl")
include("wiki.jl")
include("search.jl")

const PUZZLES_FOLDER = "puzzles"

@testset "Crosswords" begin
    for file in Base.Filesystem.readdir(PUZZLES_FOLDER)
        if endswith(file, ".jl")
            include(joinpath(PUZZLES_FOLDER, file))
        end
    end
end
