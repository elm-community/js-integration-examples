module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D



-- MAIN


main : Program () Model Msg
main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = \_ -> Sub.none
    }



-- MODEL


type alias Model =
  { language : String
  }


init : () -> ( Model, Cmd Msg )
init _ =
  ( { language = "sr-RS" }
  , Cmd.none
  )



-- UPDATE


type Msg
  = LanguageChanged String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    LanguageChanged language ->
      ( { model | language = language }
      , Cmd.none
      )



-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ p []
        [ node "intl-date"
            [ attribute "lang" model.language
            , attribute "year" "2012"
            , attribute "month" "5"
            ]
            []
        ]
    , select
        [ on "change" (D.map LanguageChanged valueDecoder)
        ]
        [ option [ value "sr-RS" ] [ text "sr-RS" ]
        , option [ value "en-GB" ] [ text "en-GB" ]
        , option [ value "en-US" ] [ text "en-US" ]
        ]
    ]


valueDecoder : D.Decoder String
valueDecoder =
  D.field "currentTarget" (D.field "value" D.string)
