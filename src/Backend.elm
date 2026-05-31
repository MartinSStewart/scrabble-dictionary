module Backend exposing (app)

import Dictionary
import Http
import Json.Decode as Decode exposing (Decoder)
import Lamdera exposing (ClientId, SessionId)
import Types exposing (..)


type alias Model =
    BackendModel


app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = \_ -> Sub.none
        }


init : ( Model, Cmd BackendMsg )
init =
    ( { lookups = 0 }
    , Cmd.none
    )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        GotDefinition clientId word isValid result ->
            let
                wordResult =
                    case result of
                        Ok meanings ->
                            { word = word
                            , isValid = isValid
                            , meanings = meanings
                            , definitionError = Nothing
                            }

                        Err err ->
                            { word = word
                            , isValid = isValid
                            , meanings = []
                            , definitionError = Just (httpErrorToMessage word err)
                            }
            in
            ( model
            , Lamdera.sendToFrontend clientId (WordChecked wordResult)
            )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend _ clientId msg model =
    case msg of
        CheckWord rawWord ->
            let
                word =
                    Dictionary.normalize rawWord

                isValid =
                    Dictionary.isValidScrabbleWord word
            in
            if String.isEmpty word then
                ( model, Cmd.none )

            else
                ( { model | lookups = model.lookups + 1 }
                , fetchDefinition clientId word isValid
                )



-- DICTIONARY API


{-| Look up a word's definition using the free Dictionary API
(<https://dictionaryapi.dev>), which needs no API key.
-}
fetchDefinition : ClientId -> String -> Bool -> Cmd BackendMsg
fetchDefinition clientId word isValid =
    Http.get
        { url = "https://api.dictionaryapi.dev/api/v2/entries/en/" ++ word
        , expect = Http.expectJson (GotDefinition clientId word isValid) meaningsDecoder
        }


{-| The API returns an array of entries; we flatten every entry's `meanings`
into a single list of part-of-speech groupings.
-}
meaningsDecoder : Decoder (List Meaning)
meaningsDecoder =
    Decode.list (Decode.field "meanings" (Decode.list meaningDecoder))
        |> Decode.map List.concat


meaningDecoder : Decoder Meaning
meaningDecoder =
    Decode.map2 Meaning
        (Decode.field "partOfSpeech" Decode.string)
        (Decode.field "definitions"
            (Decode.list (Decode.field "definition" Decode.string))
        )


httpErrorToMessage : String -> Http.Error -> String
httpErrorToMessage word err =
    case err of
        Http.BadStatus 404 ->
            "No dictionary definition found for \"" ++ word ++ "\"."

        Http.BadStatus code ->
            "The dictionary service returned an error (status " ++ String.fromInt code ++ ")."

        Http.NetworkError ->
            "Couldn't reach the dictionary service."

        Http.Timeout ->
            "The dictionary service took too long to respond."

        Http.BadUrl _ ->
            "Couldn't look up that word."

        Http.BadBody _ ->
            "No dictionary definition found for \"" ++ word ++ "\"."
