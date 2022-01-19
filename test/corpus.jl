using Test
using PuzzleTools: entries_with_prefix, is_valid_prefix
using PuzzleTools.Words: sowpods

@testset "Corpus basic tests" begin
    corpus = sowpods()
    @test "aahs" in corpus
    @test "aahx" ∉ corpus
    @test "aa" == first(corpus)
    @test "zzzs" == last(corpus)

    v = entries_with_prefix(corpus, "emitt")
    @test length(v) == 6
    @test v == split("""
emittance
emittances
emitted
emitter
emitters
emitting""")
    @test isempty(entries_with_prefix(corpus, "emitz"))
    @test entries_with_prefix(corpus, "aa") == split("""
aa
aah
aahed
aahing
aahs
aal
aalii
aaliis
aals
aardvark
aardvarks
aardwolf
aardwolves
aargh
aarrgh
aarrghh
aarti
aartis
aas
aasvogel
aasvogels""")
    @test entries_with_prefix(corpus, "zzzs") == ["zzzs"]

    @test isempty(entries_with_prefix(corpus, "`"))
    @test isempty(entries_with_prefix(corpus, "A"))
    @test entries_with_prefix(corpus, "") == corpus.sorted_entries
    @test entries_with_prefix(corpus, "b") == [w for w in corpus.sorted_entries if w[1] == 'b']
    @inferred entries_with_prefix(corpus, "")
    @inferred entries_with_prefix(corpus, "aa")
    @inferred entries_with_prefix(corpus, "abc")

    @test is_valid_prefix(corpus, "aa")
    @test !is_valid_prefix(corpus, "axx")


end
