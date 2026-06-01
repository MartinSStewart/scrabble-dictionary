module Frontend exposing (app)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Html exposing (Html)
import Lamdera
import Types exposing (..)
import Ui exposing (Element)
import Ui.Events
import Ui.Font
import Ui.Input
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



-- COLORS


type alias Color =
    Ui.Color


pageBg : Color
pageBg =
    Ui.rgb 240 244 248


cardBg : Color
cardBg =
    Ui.rgb 255 255 255


ink : Color
ink =
    Ui.rgb 31 41 51


muted : Color
muted =
    Ui.rgb 82 96 109


faint : Color
faint =
    Ui.rgb 123 135 148


inputBorder : Color
inputBorder =
    Ui.rgb 203 210 217


accent : Color
accent =
    Ui.rgb 59 130 246


validBg : Color
validBg =
    Ui.rgb 227 249 229


validInk : Color
validInk =
    Ui.rgb 32 114 39


invalidBg : Color
invalidBg =
    Ui.rgb 255 227 227


invalidInk : Color
invalidInk =
    Ui.rgb 166 27 27



-- VIEW


view : Model -> Browser.Document FrontendMsg
view model =
    { title = "Scrabble Word Checker"
    , body =
        [ Ui.layout
            [ Ui.background pageBg
            , Ui.height Ui.fill
            , Ui.paddingXY 16 32
            , Ui.Font.color ink
            , Ui.Font.size 16
            ]
            (Ui.el
                [ Ui.centerX
                , Ui.width Ui.fill
                , Ui.widthMax 560
                , Ui.contentTop
                ]
                (card model)
            )
        ]
    }


card : Model -> Element FrontendMsg
card model =
    Ui.column
        [ Ui.background cardBg
        , Ui.rounded 16
        , Ui.padding 24
        , Ui.width Ui.fill
        , Ui.spacing 20
        ]
        [ Ui.column [ Ui.spacing 8 ]
            [ Ui.el [ Ui.Font.size 26, Ui.Font.bold ] (Ui.text "Scrabble Word Checker")
            , Ui.el [ Ui.Font.size 15, Ui.Font.color muted ]
                (Ui.text "Type a word and press Enter to check if it's a valid Scrabble word (TWL06).")
            ]
        , viewForm model
        , viewResult model.status
        ]


viewForm : Model -> Element FrontendMsg
viewForm model =
    Ui.row [ Ui.width Ui.fill, Ui.spacing 8 ]
        [ Ui.Input.text
            [ Ui.width Ui.fill
            , Ui.padding 12
            , Ui.rounded 10
            , Ui.border 2
            , Ui.borderColor inputBorder
            , Ui.Font.size 18
            , Ui.Events.onKey Ui.Events.enter Submit
            ]
            { onChange = InputChanged
            , text = model.input
            , placeholder = Just "e.g. qi"
            , label = Ui.Input.labelHidden "Word to check"
            }
        , Ui.el
            [ Ui.Input.button Submit
            , Ui.background accent
            , Ui.Font.color (Ui.rgb 255 255 255)
            , Ui.Font.bold
            , Ui.rounded 10
            , Ui.paddingXY 18 12
            , Ui.pointer
            , Ui.contentCenterY
            ]
            (Ui.text "Check")
        ]


viewResult : Status -> Element FrontendMsg
viewResult status =
    case status of
        Idle ->
            Ui.none

        Loading word ->
            Ui.el [ Ui.Font.color muted, Ui.Font.italic ]
                (Ui.text ("Checking \"" ++ word ++ "\"\u{2026}"))

        Loaded result ->
            Ui.column [ Ui.width Ui.fill, Ui.spacing 20 ]
                [ viewVerdict result
                , viewDefinition result
                ]


viewVerdict : WordResult -> Element FrontendMsg
viewVerdict result =
    let
        ( bg, fg, message ) =
            if result.isValid then
                ( validBg
                , validInk
                , "\u{2713}  \"" ++ result.word ++ "\" is a valid Scrabble word!"
                )

            else
                ( invalidBg
                , invalidInk
                , "\u{2717}  \"" ++ result.word ++ "\" is not a valid Scrabble word."
                )
    in
    Ui.el
        [ Ui.background bg
        , Ui.Font.color fg
        , Ui.Font.bold
        , Ui.Font.size 18
        , Ui.width Ui.fill
        , Ui.rounded 10
        , Ui.padding 14
        ]
        (Ui.text message)


viewDefinition : WordResult -> Element FrontendMsg
viewDefinition result =
    case ( result.meanings, result.definitionError ) of
        ( [], Just err ) ->
            Ui.el [ Ui.Font.color faint, Ui.Font.italic ] (Ui.text err)

        ( [], Nothing ) ->
            Ui.el [ Ui.Font.color faint, Ui.Font.italic ] (Ui.text "No definition available.")

        ( meanings, _ ) ->
            Ui.column [ Ui.width Ui.fill, Ui.spacing 14 ]
                (Ui.el
                    [ Ui.Font.size 13
                    , Ui.Font.bold
                    , Ui.Font.color faint
                    ]
                    (Ui.text "DEFINITION")
                    :: List.map viewMeaning meanings
                )


viewMeaning : Meaning -> Element FrontendMsg
viewMeaning meaning =
    Ui.column [ Ui.width Ui.fill, Ui.spacing 6 ]
        (Ui.el [ Ui.Font.italic, Ui.Font.color muted ] (Ui.text meaning.partOfSpeech)
            :: List.indexedMap viewNumberedDefinition (List.take 3 meaning.definitions)
        )


viewNumberedDefinition : Int -> String -> Element FrontendMsg
viewNumberedDefinition index definition =
    Ui.row [ Ui.width Ui.fill, Ui.spacing 8, Ui.contentTop ]
        [ Ui.el [ Ui.width (Ui.px 16), Ui.Font.color faint ] (Ui.text (String.fromInt (index + 1) ++ "."))
        , Ui.el [ Ui.width Ui.fill ] (Ui.text definition)
        ]
