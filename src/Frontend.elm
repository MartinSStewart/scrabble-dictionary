module Frontend exposing (app)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Lamdera
import Types exposing (..)
import Url


type alias Model =
    FrontendModel


app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = \_ -> Sub.none
        , view = view
        }


init : Url.Url -> Nav.Key -> ( Model, Cmd FrontendMsg )
init _ key =
    ( { key = key
      , input = ""
      , status = Idle
      }
    , Cmd.none
    )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                External url ->
                    ( model, Nav.load url )

        UrlChanged _ ->
            ( model, Cmd.none )

        InputChanged value ->
            ( { model | input = value }, Cmd.none )

        Submit ->
            let
                trimmed =
                    String.trim model.input
            in
            if String.isEmpty trimmed then
                ( model, Cmd.none )

            else
                ( { model | status = Loading trimmed }
                , Lamdera.sendToBackend (CheckWord trimmed)
                )

        NoOpFrontendMsg ->
            ( model, Cmd.none )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        WordChecked result ->
            -- Ignore stale results if the user has already moved on to a
            -- different word.
            case model.status of
                Loading pending ->
                    if String.toLower pending == String.toLower result.word then
                        ( { model | status = Loaded result }, Cmd.none )

                    else
                        ( model, Cmd.none )

                _ ->
                    ( { model | status = Loaded result }, Cmd.none )



-- VIEW


view : Model -> Browser.Document FrontendMsg
view model =
    { title = "Scrabble Word Checker"
    , body =
        [ Html.node "style" [] [ Html.text css ]
        , Html.div [ Attr.class "page" ]
            [ Html.div [ Attr.class "card" ]
                [ Html.h1 [ Attr.class "title" ] [ Html.text "Scrabble Word Checker" ]
                , Html.p [ Attr.class "subtitle" ]
                    [ Html.text "Type a word and press Enter to check if it's a valid Scrabble word (TWL06)." ]
                , viewForm model
                , viewResult model.status
                ]
            ]
        ]
    }


viewForm : Model -> Html FrontendMsg
viewForm model =
    Html.form [ Attr.class "form", Events.onSubmit Submit ]
        [ Html.input
            [ Attr.class "input"
            , Attr.type_ "text"
            , Attr.value model.input
            , Attr.autofocus True
            , Attr.attribute "autocomplete" "off"
            , Attr.attribute "autocapitalize" "none"
            , Attr.spellcheck False
            , Events.onInput InputChanged
            ]
            []
        , Html.button [ Attr.class "button", Attr.type_ "submit" ] [ Html.text "Check" ]
        ]


viewResult : Status -> Html FrontendMsg
viewResult status =
    case status of
        Idle ->
            Html.text ""

        Loading word ->
            Html.div [ Attr.class "result" ]
                [ Html.p [ Attr.class "loading" ]
                    [ Html.text ("Checking \"" ++ word ++ "\"…") ]
                ]

        Loaded result ->
            Html.div [ Attr.class "result" ]
                [ viewVerdict result
                , viewDefinition result
                ]


viewVerdict : WordResult -> Html FrontendMsg
viewVerdict result =
    let
        ( cls, symbol, message ) =
            if result.isValid then
                ( "verdict valid"
                , "✓"
                , "\"" ++ result.word ++ "\" is a valid Scrabble word!"
                )

            else
                ( "verdict invalid"
                , "✗"
                , "\"" ++ result.word ++ "\" is not a valid Scrabble word."
                )
    in
    Html.div [ Attr.class cls ]
        [ Html.span [ Attr.class "symbol" ] [ Html.text symbol ]
        , Html.span [] [ Html.text message ]
        ]


viewDefinition : WordResult -> Html FrontendMsg
viewDefinition result =
    case ( result.meanings, result.definitionError ) of
        ( [], Just err ) ->
            Html.p [ Attr.class "def-note" ] [ Html.text err ]

        ( [], Nothing ) ->
            Html.p [ Attr.class "def-note" ] [ Html.text "No definition available." ]

        ( meanings, _ ) ->
            Html.div [ Attr.class "definitions" ]
                (Html.h2 [ Attr.class "def-heading" ] [ Html.text "Definition" ]
                    :: List.map viewMeaning meanings
                )


viewMeaning : Meaning -> Html FrontendMsg
viewMeaning meaning =
    Html.div [ Attr.class "meaning" ]
        [ Html.div [ Attr.class "pos" ] [ Html.text meaning.partOfSpeech ]
        , Html.ol [ Attr.class "def-list" ]
            (List.map
                (\d -> Html.li [] [ Html.text d ])
                (List.take 3 meaning.definitions)
            )
        ]


css : String
css =
    """
* { box-sizing: border-box; }
body { margin: 0; }
.page {
    min-height: 100vh;
    display: flex;
    align-items: flex-start;
    justify-content: center;
    padding: 48px 16px;
    background: linear-gradient(160deg, #f0f4f8 0%, #d9e2ec 100%);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    color: #1f2933;
}
.card {
    width: 100%;
    max-width: 560px;
    background: #ffffff;
    border-radius: 16px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.08);
    padding: 32px;
}
.title { margin: 0 0 8px; font-size: 28px; }
.subtitle { margin: 0 0 24px; color: #52606d; font-size: 15px; }
.form { display: flex; gap: 8px; }
.input {
    flex: 1;
    padding: 12px 14px;
    font-size: 18px;
    border: 2px solid #cbd2d9;
    border-radius: 10px;
    outline: none;
    transition: border-color 0.15s ease;
}
.input:focus { border-color: #3b82f6; }
.button {
    padding: 12px 20px;
    font-size: 16px;
    font-weight: 600;
    color: #ffffff;
    background: #3b82f6;
    border: none;
    border-radius: 10px;
    cursor: pointer;
    transition: background 0.15s ease;
}
.button:hover { background: #2563eb; }
.result { margin-top: 24px; }
.loading { color: #52606d; font-style: italic; }
.verdict {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 14px 16px;
    border-radius: 10px;
    font-size: 18px;
    font-weight: 600;
}
.verdict .symbol { font-size: 22px; }
.verdict.valid { background: #e3f9e5; color: #207227; }
.verdict.invalid { background: #ffe3e3; color: #a61b1b; }
.definitions { margin-top: 20px; }
.def-heading { font-size: 16px; text-transform: uppercase; letter-spacing: 0.05em; color: #7b8794; margin: 0 0 8px; }
.meaning { margin-bottom: 14px; }
.pos { font-style: italic; color: #3e4c59; margin-bottom: 4px; }
.def-list { margin: 0; padding-left: 22px; line-height: 1.5; }
.def-list li { margin-bottom: 4px; }
.def-note { margin-top: 16px; color: #7b8794; font-style: italic; }
"""
