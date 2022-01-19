using Test
using PuzzleTools.Wiki

@testset "Wiki Queries" begin
    results = Wiki.search("fish")
    @test "Salmon" in title.(links(first(results)))
    @test "goose" in Wiki.corpus("bird")
end
