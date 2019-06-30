module Message.Remote exposing (Msg(..))

import Model.Game exposing (DbGame, Game)
import Model.GlobalHighscoreItem exposing (GlobalHighscoreItem)
import Model.User exposing (User)
import Model.Value exposing (DbValue, Value)
import Model.WindowState exposing (WindowState)


type Msg
    = RemoteUsers (List User)
    | RemoteValuesReceived (List DbValue)
    | GameReceived (Maybe DbGame)
    | GamesReceived (List DbGame)
    | GlobalHighscoreReceived (List GlobalHighscoreItem)
    | WindowStateReceived WindowState
