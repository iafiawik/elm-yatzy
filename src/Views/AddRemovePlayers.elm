module Views.AddRemovePlayers exposing (addRemovePlayers)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Models exposing (Model, Msg(..), Player)


playerButton : Player -> List (Html Msg) -> Html Msg
playerButton player content =
    button [ class "add-players-dialog-player-button" ] [ span [] [ text player.name ], button [ onClick (RemovePlayer player), class "add-players-dialog-player-button-delete" ] [ text "X" ], div [] ([] ++ content) ]


addRemovePlayers : Model -> Html Msg
addRemovePlayers model =
    let
        playerButtons =
            List.map
                (\p ->
                    playerButton p
                        []
                )
                model.players
    in
    div [ class "add-players-dialog-wrapper dialog-wrapper" ]
        [ div [ class "add-players-dialog-background dialog-background animated fadeIn" ] []
        , div [ class "add-players-dialog dialog-content a animated jackInTheBox" ]
            [ div [] [ h1 [] [ text "Yatzy" ], h2 [] [ text "Add players" ] ]
            , div [ class "add-players-dialog-player-buttons" ] playerButtons
            , div []
                [ input [ class "add-players-dialog-input-field", type_ "text", onInput NewPlayerInputValueChange, value model.currentNewPlayerName ] []
                , button [ onClick AddPlayer ] [ text "Add new player" ]
                ]
            , button [ class "large-button  ", onClick Start ] [ text "Start" ]
            ]
        ]
