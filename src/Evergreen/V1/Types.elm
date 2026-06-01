module Evergreen.V1.Types exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V1.Word
import Http
import Lamdera
import Url


type alias Meaning =
    { partOfSpeech : String
    , definitions : List String
    }


type alias WordResult =
    { word : Evergreen.V1.Word.Word
    , isValid : Bool
    , meanings : List Meaning
    , definitionError : Maybe String
    }


type Status
    = Idle
    | Loading Evergreen.V1.Word.Word (Maybe Bool)
    | Loaded WordResult
    | InvalidWord String


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , input : String
    , status : Status
    , windowWidth : Int
    , windowHeight : Int
    }


type alias BackendModel =
    { lookups : Int
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | InputChanged String
    | Submit
    | GotWindowSize Int Int
    | NoOpFrontendMsg


type ToBackend
    = CheckWord Evergreen.V1.Word.Word


type BackendMsg
    = GotDefinition Lamdera.ClientId Evergreen.V1.Word.Word Bool (Result Http.Error (List Meaning))


type ToFrontend
    = WordDefinitionResponse WordResult
    | WordCheckedResponse Evergreen.V1.Word.Word Bool
