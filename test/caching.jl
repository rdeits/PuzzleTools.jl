using Base.Test

module cachingtest
    import Caching: @cached

    type Foo
        bar::Nullable{Int}
        baz::Nullable{Float64}

        Foo() = new(Nullable{Int}(), Nullable{Float64}())
    end

    bar_counter = 0

    # println(macroexpand(:(@cached function bar(foo::Foo)
    #         println("running bar")
    #         println(foo)
    #         global bar_counter
    #         bar_counter += 1
    #         6
    #     end)))

    @cached function bar(foo::Foo)
        global bar_counter
        bar_counter += 1
        6
    end

    baz_counter = 0
    @cached baz(foo) = begin
        global baz_counter
        baz_counter += 1
        1.0
    end
end

@testset "caching" begin
    f = cachingtest.Foo()
    @test cachingtest.bar(f) == 6
    @test cachingtest.bar_counter == 1
    @test cachingtest.bar(f) == 6
    @test cachingtest.bar_counter == 1

    @test cachingtest.baz(f) == 1.0
    @test cachingtest.baz_counter == 1
    @test cachingtest.baz(f) == 1.0
    @test cachingtest.baz_counter == 1
end
