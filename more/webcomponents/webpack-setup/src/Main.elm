module Main exposing (main)

import Browser
import Html exposing (Html)


update : () -> {} -> {}
update msg model =
    model


view : {} -> Html msg
view model =
    Html.text "Hello, World!"


main : Program () {} ()
main =
    Browser.sandbox
        { init = {}
        , update = update
        , view = view
        }
