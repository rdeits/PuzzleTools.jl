using Test
using PuzzleTools

module cachingtest
    import PuzzleTools.Caching: @cached

    mutable struct Foo
        bar::Union{Int, Missing}
        baz::Union{Float64, Missing}

        Foo() = new(missing, missing)
    end

    bar_counter = Ref(0)

    @cached function bar(foo::Foo)
        bar_counter[] += 1
        6
    end

    baz_counter = Ref(0)
    @cached baz(foo) = begin
        baz_counter[] += 1
        1.0
    end
end

@testset "caching" begin
    f = cachingtest.Foo()
    @test cachingtest.bar(f) == 6
    @test cachingtest.bar_counter[] == 1
    @test cachingtest.bar(f) == 6
    @test cachingtest.bar_counter[] == 1

    @test cachingtest.baz(f) == 1.0
    @test cachingtest.baz_counter[] == 1
    @test cachingtest.baz(f) == 1.0
    @test cachingtest.baz_counter[] == 1
end
