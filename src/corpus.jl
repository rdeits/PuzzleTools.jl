const Stringy = Union{AbstractString, AbstractVector{Char}}

struct Corpus
    sorted_entries::Vector{String}
    set::Set{String}

    Corpus(entries) = new(sort(entries), Set{String}(entries))
end

Base.in(entry::AbstractString, corpus::Corpus) = entry in corpus.set
Base.eltype(::Type{Corpus}) = String
Base.length(c::Corpus) = length(c.sorted_entries)
Base.getindex(c::Corpus, i) = getindex(c.sorted_entries, i)
Base.iterate(c::Corpus, args...) = iterate(c.sorted_entries, args...)
Base.firstindex(c::Corpus) = firstindex(c.sorted_entries)
Base.lastindex(c::Corpus) = lastindex(c.sorted_entries)
Base.filter(f, c::Corpus) = Corpus(filter(f, c.sorted_entries))

_startswith(v1::AbstractVector, v2::AbstractVector) = @view(v1[1:length(v2)]) == v2
_startswith(v1::AbstractString, v2::AbstractString) = startswith(v1, v2)

function is_valid_prefix(sorted_entries::AbstractVector{<:Stringy}, prefix::Stringy)
    if isempty(prefix)
        return true
    end
    i = searchsortedfirst(sorted_entries, prefix)
    return i <= length(sorted_entries) && _startswith(sorted_entries[i], prefix)
end

is_valid_prefix(corpus::Corpus, prefix::Stringy) = is_valid_prefix(corpus.sorted_entries, prefix)

function next_string(s::AbstractString)
    c = last(s)
    string(s[1:prevind(s, end)], c + 1)
end

function next_string(s::AbstractVector)
    s = copy(s)
    s[end] += 1
    s
end

function entries_with_prefix(sorted_entries::AbstractVector{<:Stringy}, prefix::Stringy)
    if isempty(prefix)
        return @view(sorted_entries[begin:end])
    end
    first = searchsortedfirst(sorted_entries, prefix)
    if first > length(sorted_entries) || !_startswith(sorted_entries[first], prefix)
        return @view(sorted_entries[first:first-1])
    end
    last = searchsortedfirst(@view(sorted_entries[(first + 1):end]), next_string(prefix)) - 1
    @view(sorted_entries[first:(first + last)])
end

entries_with_prefix(corpus::Corpus, prefix::Stringy) = entries_with_prefix(corpus.sorted_entries, prefix)
