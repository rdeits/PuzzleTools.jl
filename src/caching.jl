module Caching

export @cached

esc_type(arg::Symbol) = arg
function esc_type(arg::Expr)
    @assert arg.head == :(::)
    Expr(:(::), arg.args[1], esc(arg.args[2]))
end

argument_name(arg::Symbol) = arg
function argument_name(arg::Expr)
    @assert arg.head == :(::)
    arg.args[1]
end

macro cached(definition::Expr)
    @assert(definition.head == :function || definition.head == :(=),
           "Expected a function declaration")
    signature = definition.args[1]
    args = signature.args[2:end]
    @assert(length(args) == 1,
            "Expected a function taking exactly one argument")
    body = definition.args[2]
    @assert signature.head == :call

    attribute = signature.args[1]
    object = esc_type(signature.args[2])

    inner_function_name = gensym(attribute)
    inner_function = Expr(:function,
        Expr(:call, esc(inner_function_name), object),
            Expr(:block,
                # TODO: remove this when
                # https://github.com/JuliaLang/julia/issues/16096
                # is resolved
                Expr(:(=),
                    esc(argument_name(signature.args[2])),
                    object
                ),
                esc(body)
            )
        )

    outer_function = Expr(:function,
    Expr(:call, esc(attribute), object),
    quote
        if isnull($(object).$(attribute))
            $(object).$(attribute) = Nullable($(esc(inner_function_name))($(object)))
        end
        get($(object).$(attribute))
    end
    )

    quote
        $(inner_function)
        $(outer_function)
    end
end

end
