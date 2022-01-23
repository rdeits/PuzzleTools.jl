module Bitsets

export AbstractBitmaskSet, exactly_one_element, data, decode, encode

abstract type AbstractBitmaskSet{T} <: AbstractSet{T} end

function data end
function alphabet end

function (::Type{T})(elements::AbstractVector) where {T <: AbstractBitmaskSet}
    reduce((x, y) -> x ∪ T(y), elements, init=T())
end

# Clever math trick via https://stackoverflow.com/a/51094793/641846
exactly_one_bit_set(x::Integer) = !iszero(x) && iszero(x & (x - 1))

exactly_one_element(m::AbstractBitmaskSet) = exactly_one_bit_set(data(m))

function Base.only(mask::M) where {M <: AbstractBitmaskSet}
    exactly_one_element(mask) || throw(ArgumentError("Mask must contain exactly one element"))
    alphabet(M)[sizeof(data(mask)) << 3 - leading_zeros(data(mask))]
end

function Base.length(mask::AbstractBitmaskSet)
    d = data(mask)
    result = 0
    while true
        if iszero(d)
            return result
        end
        result += d & 1
        d >>= 1
    end
end

Base.intersect(m1::T, m2::T) where {T <: AbstractBitmaskSet} = T(data(m1) & data(m2))

Base.union(m1::T, m2::T) where {T <: AbstractBitmaskSet} = T(data(m1) | data(m2))

Base.setdiff(m1::T, m2::T) where {T <: AbstractBitmaskSet} = T(data(m1) & ~data(m2))

function Base.iterate(mask::M, state = (data(mask), 1)) where {M <: AbstractBitmaskSet}
    shifted_data, index = state
    while !iszero(shifted_data)
        found = !iszero(shifted_data & 1)
        shifted_data >>= 1
        index += 1
        if found
            return alphabet(M)[index - 1], (shifted_data, index)
        end
    end
end

Base.IteratorSize(::Type{T}) where {T <: AbstractBitmaskSet} = Base.SizeUnknown()

Base.isempty(mask::AbstractBitmaskSet) = iszero(data(mask))

Base.in(element, mask::T) where {T <: AbstractBitmaskSet} = !isempty(T(element) ∩ mask)

Base.isless(m1::T, m2::T) where {T <: AbstractBitmaskSet} = data(m1) < data(m2)

end
