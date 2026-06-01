module Dictionary exposing (isValidScrabbleWord, normalize)

import Set exposing (Set)
import Word exposing (Word)
import Words


wordSet : Set String
wordSet =
    Words.raw
        |> String.words
        |> Set.fromList


normalize : String -> String
normalize word =
    String.toLower (String.trim word)


{-| Is the given word playable in Scrabble according to TWL06?
-}
isValidScrabbleWord : Word -> Bool
isValidScrabbleWord word =
    Set.member (Word.toString word) wordSet
