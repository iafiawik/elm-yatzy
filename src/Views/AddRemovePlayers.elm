module Views.AddRemovePlayers exposing (addRemovePlayers)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import List.Extra exposing (find)
import Model.User exposing (User)
import Models exposing (GameSetup, Model(..), Msg(..), Player)


playerButton : Player -> List (Html Msg) -> Html Msg
playerButton player content =
    button [ class "add-players-dialog-player-button" ] [ span [] [ text player.user.name ], button [ onClick (RemovePlayer player), class "add-players-dialog-player-button-delete" ] [ text "X" ], div [] ([] ++ content) ]


userButton : User -> List (Html Msg) -> Html Msg
userButton user content =
    button [ class "add-players-dialog-user-button" ] [ span [] [ text user.name ], button [ onClick (AddPlayer user), class "add-players-dialog-player-button-delete" ] [ text "Add" ], div [] ([] ++ content) ]


addRemovePlayers : GameSetup -> Html Msg
addRemovePlayers model =
    let
        playerButtons =
            List.map
                (\p ->
                    playerButton p
                        []
                )
                model.players

        availableUsers =
            List.filter
                (\u ->
                    if find (\p -> p.user.id == u.id) model.players == Nothing then
                        True

                    else
                        False
                )
                model.users

        userButtons =
            List.map
                (\u ->
                    userButton u
                        []
                )
                availableUsers
    in
    div [ class "add-players-dialog-wrapper dialog-wrapper" ]
        [ div [ class "add-players-dialog-background dialog-background animated fadeIn" ] []
        , div [ class "add-players-dialog dialog-content a animated jackInTheBox" ]
            [ div [] [ h1 [] [ text "Yatzy" ], h2 [] [ text "Add players" ] ]
            , div [ class "add-players-dialog-player-buttons" ] playerButtons
            , div [ class "add-players-dialog-user-buttons" ] userButtons
            , div []
                [ input [ class "add-players-dialog-input-field", type_ "text", onInput NewPlayerInputValueChange, value model.currentNewPlayerName ] []
                , button [ onClick AddUser ] [ text "Add new player" ]
                ]
            , button [ class "large-button  ", onClick Start ] [ text "Start" ]
            ]
        ]
