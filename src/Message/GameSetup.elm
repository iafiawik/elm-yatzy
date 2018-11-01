module Message.GameSetup exposing (Msg(..))

import Model.Player exposing (Player)
import Model.User exposing (User)


type Msg
    = AddUser
    | AddPlayer User
    | RemovePlayer Player
    | NewPlayerInputValueChange String
    | PlayersAdded
    | Start
    | InputValueChange String
    | GameCodeInputChange String
    | EnterGame
    | PlayerMarked Player
    | AllPlayersMarked
