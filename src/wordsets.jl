module Wordsets

typealias Wordset Set{String}

cleanup_phrase(phrase) = replace(lowercase(phrase), r"[^a-z ]", "")

read_dictionary(file) = Set(cleanup_phrase.(readdlm(file, '\t', String)))

UKACD() = read_dictionary("data/UKACD.txt")
sowpods() = read_dictionary("data/sowpods.txt")
unixwords() = Set(cleanup_phrase.(readdlm("/usr/share/dict/words", '\t', String, use_mmap=false)))

module Wikipedia
    import Wordsets: Wordset, cleanup_phrase
    using Wiki

    cleanup_wiki_title(title) = replace(title, r"\([^\)]*\)", "")

    function wordset(title)
        titles = links(WikiPage(title))
        Wordset(cleanup_phrase.(cleanup_wiki_title.(titles)))
    end
end

end
