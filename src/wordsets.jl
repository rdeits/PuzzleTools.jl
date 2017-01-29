module Wordsets

typealias Wordset Set{String}

cleanup_phrase(phrase) = replace(lowercase(phrase), r"[^a-z ]", "")

read_dictionary(file) = cleanup_phrase.(vec(readdlm(file, '\t', String)))

UKACD() = read_dictionary(joinpath(dirname(@__FILE__), "..", "data", "UKACD.txt"))
sowpods() = read_dictionary(joinpath(dirname(@__FILE__), "..", "data", "sowpods.txt"))
unixwords() = cleanup_phrase.(vec(readdlm("/usr/share/dict/words", '\t', String, use_mmap=false)))

module Wikipedia
    import PuzzleTools.Wordsets: Wordset, cleanup_phrase
    using PuzzleTools.Wiki

    cleanup_wiki_title(title) = replace(title, r"\([^\)]*\)", "")

    function wordset(title)
        titles = links(WikiPage(title))
        Wordset(cleanup_phrase.(cleanup_wiki_title.(titles)))
    end
end

end
