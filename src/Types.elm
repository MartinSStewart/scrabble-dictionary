module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Http
import Lamdera exposing (ClientId)
import Url exposing (Url)
import Word exposing (Word)


type alias FrontendModel =
    { key : Key
    , input : String
    , status : Status
    , windowWidth : Int
    , windowHeight : Int
    }


{-| The lifecycle of a single word lookup as seen by the frontend.
-}
type Status
    = Idle
    | Loading Word (Maybe Bool)
    | Loaded WordResult
    | InvalidWord String


type alias BackendModel =
    { lookups : Int
    }


type alias WordResult =
    { word : Word
    , isValid : Bool
    , meanings : List Meaning
    , definitionError : Maybe String
    }


{-| A single part-of-speech grouping from the dictionary API,
e.g. "noun" with a handful of definitions.
-}
type alias Meaning =
    { partOfSpeech : String
    , definitions : List String
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | InputChanged String
    | Submit
    | GotWindowSize Int Int
    | NoOpFrontendMsg


type ToBackend
    = CheckWord Word


type BackendMsg
    = GotDefinition ClientId Word Bool (Result Http.Error (List Meaning))


type ToFrontend
    = WordDefinitionResponse WordResult
    | WordCheckedResponse Word Bool
