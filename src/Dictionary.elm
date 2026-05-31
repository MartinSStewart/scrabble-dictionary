module Dictionary exposing (isValidScrabbleWord, normalize)

import Set exposing (Set)
import Words


{-| The full TWL06 word list as a set, for O(log n) membership checks.

This is a top-level constant, so Elm evaluates it lazily exactly once and
caches the result for the lifetime of the backend process. That means the
178k-word set is built on first use and never rebuilt, and it never has to
live inside (and bloat) the persisted `BackendModel`.

-}
wordSet : Set String
wordSet =
    Words.raw
        |> String.words
        |> Set.fromList


{-| Words in the dictionary are lowercase with surrounding whitespace removed.
-}
normalize : String -> String
normalize word =
    String.toLower (String.trim word)


{-| Is the given word playable in Scrabble according to TWL06?
-}
isValidScrabbleWord : String -> Bool
isValidScrabbleWord word =
    Set.member (normalize word) wordSet
