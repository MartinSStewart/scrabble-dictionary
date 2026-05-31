module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Http
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , input : String
    , status : Status
    }


{-| The lifecycle of a single word lookup as seen by the frontend.
-}
type Status
    = Idle
    | Loading String
    | Loaded WordResult


type alias BackendModel =
    { lookups : Int
    }


type alias WordResult =
    { word : String
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
    | NoOpFrontendMsg


type ToBackend
    = CheckWord String


type BackendMsg
    = GotDefinition String String Bool (Result Http.Error (List Meaning))


type ToFrontend
    = WordChecked WordResult
