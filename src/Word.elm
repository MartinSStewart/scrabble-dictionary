module Word exposing (Word, fromString, toString)


type Word
    = Word Char String


fromString : String -> Result String Word
fromString text =
    let
        text2 =
            String.trim text |> String.toLower
    in
    if String.all Char.isAlpha text2 then
        case String.uncons text2 of
            Just ( head, rest ) ->
                Word head rest |> Ok

            Nothing ->
                Err "Word must be at least 1 letter long"

    else
        Err "Word can only use the basic latin alphabet (A-Z)"


toString : Word -> String
toString (Word a b) =
    String.cons a b
