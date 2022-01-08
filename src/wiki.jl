module Wiki

export WikiPage,
       links,
       content,
       title,
       wordset

using HTTP: request
using JSON
using ..Caching
using ..Wordsets: cleanup_phrase

struct MediaWiki
    url::String
end

wikipedia = MediaWiki("https://en.wikipedia.org/w/api.php")

function wiki_request(query_params, wiki::MediaWiki=wikipedia)
    query = Dict(
        "format" => "json",
        "action" => "query",
        query_params...
    )
    response = request("GET", wiki.url, query=query)
    JSON.parse(String(response.body))
end

mutable struct WikiPage
    title::String
    wiki::MediaWiki
    links::Union{Vector{WikiPage}, Missing}
    content::Union{String, Missing}

    WikiPage(title, wiki=wikipedia) = new(title,
        wiki,
        missing, missing)
end


"""
Based on https://www.mediawiki.org/wiki/API:Query#Continuing_queries
"""
function continued_query(page::WikiPage, query_params)
    continuation = Dict{String, String}()
    prop = query_params["prop"]
    results = []

    while true
        response = wiki_request(Dict(
            "titles" => page.title,
            continuation...,
            query_params...
        ), page.wiki)
        for (page_id, page_data) in response["query"]["pages"]
            append!(results, page_data[prop])
        end
        if "continue" in keys(response)
            continuation = response["continue"]
        else
            break
        end
    end
    results
end

function search(query, wiki::MediaWiki=wikipedia;
                results::Integer=10)
    result = wiki_request(Dict(
        "list" => "search",
        "srprop" => "",
        "srlimit" => results,
        "limit" => results,
        "srsearch" => query
    ), wiki)
    [WikiPage(d["title"]) for d in result["query"]["search"]]
end

function suggest(query, wiki::MediaWiki=wikipedia)
    result = wiki_request(Dict(
        "list" => "search",
        "srinfo" => "suggestion",
        "srprop" => "",
        "srsearch" => query,
    ), wiki)
    if "searchinfo" in keys(result["query"])
        result["query"]["searchinfo"]["suggestion"]
    else
        ""
    end
end

title(page::WikiPage) = page.title

@cached function links(page::WikiPage)
    raw_links = continued_query(page, Dict(
        "prop" => "links",
        "plnamespace" => 0,
        "pllimit" => "max",
    ))
    [WikiPage(d["title"]) for d in raw_links]
end

@cached function content(page::WikiPage)
    continued_query(page, Dict(
        "prop" => "revisions",
        "rvprop" => "content"
    ))[1]["*"]::String
end

cleanup_wiki_title(title) = replace(title, r"\([^\)]*\)" => "")

function wordset(query)
    Set{String}(cleanup_phrase.(cleanup_wiki_title.(title.(links(first(search(query)))))))
end

end
