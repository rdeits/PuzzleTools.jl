module Caching

using MacroTools: splitdef

export @cached

"""
Create a single-argument function which caches its result in a struct field
of the same name within that argument.
"""
macro cached(definition::Expr)
    components = splitdef(definition)
    name = components[:name]
    @assert length(components[:args]) == 1 "Expected a function of one argument"
    @assert length(components[:kwargs]) == 0 "Expected a function with no keyword arguments"
    obj = only(components[:args])

    quote
        $(esc(components[:name]))($(esc.(components[:args])...)) = begin
            if ($(esc(obj)).$(name)) === missing
                ($(esc(obj)).$(name)) = $(esc(components[:body]))
            end
            $(esc(obj)).$(name)
        end
    end
end

end
