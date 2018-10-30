module Models exposing (GamePlaying, GameResult, GameResultState(..), GameSetup, GroupModel(..), IndividualModel(..), IndividualPlayingModel, IndividualPostGameModel, MarkedPlayer(..), Mode(..), Model(..), Msg(..), PlayerAndNumberOfValues, PreGameState(..), SelectPlayerModel)

import Json.Decode exposing (Decoder, field, int, map3, string)
import Model.Box exposing (Box)
import Model.Error exposing (Error(..))
import Model.Game exposing (DbGame, Game)
import Model.GameState exposing (GameState)
import Model.GlobalHighscoreItem exposing (GlobalHighscoreItem)
import Model.Player exposing (Player)
import Model.User exposing (User)
import Model.Value exposing (DbValue, Value)
import Time
import Uuid


type Msg
    = SelectGroup
    | SelectIndividual
    | EnterGame
    | PlayerMarked Player
    | AllPlayersMarked
    | AddRemovePlayers
    | AddUser
    | RemoteUsers (List User)
    | RemoteValuesReceived (List DbValue)
    | GameReceived (Maybe DbGame)
    | GamesReceived (List DbGame)
    | GlobalHighscoreReceived (List GlobalHighscoreItem)
    | AddPlayer User
    | RemovePlayer Player
    | NewPlayerInputValueChange String
    | PlayersAdded
    | Start
    | AddValue
    | RemoveValue
    | ShowAddValue Box
    | ShowEditValue Value
    | ValueMarked Int
    | HideAddValue
    | InputValueChange String
    | GameCodeInputChange String
    | CountValues
    | CountValuesTick Time.Posix
    | Restart
    | HideNotification
    | ShowGameInfo
    | HideGameInfo
    | FillWithDummyValues Player
    | NoOp



-- type Error a b
--     = Just a b
--     | Nothing


type Model
    = SelectedMode Mode


type Mode
    = SelectMode (List GlobalHighscoreItem)
    | Individual IndividualModel
    | Group GroupModel


type IndividualModel
    = EnterGameCode String (List Game)
    | WaitingForData ( Maybe Game, Maybe (List DbValue) )
    | SelectPlayer SelectPlayerModel
    | IndividualPlaying IndividualPlayingModel
    | IndividualPostGame IndividualPostGameModel


type GroupModel
    = PreGame GameSetup
    | Playing GamePlaying
    | PostGame GameResult


type MarkedPlayer
    = Single Player
    | All
    | NoPlayer


type alias SelectPlayerModel =
    { game : Game
    , markedPlayer : MarkedPlayer
    }


type alias IndividualPlayingModel =
    { gamePlaying : GamePlaying
    , selectedPlayer : Player
    }


type alias IndividualPostGameModel =
    { game : Game
    , selectedPlayer : Player
    }


type alias GameSetup =
    { users : List User
    , currentNewPlayerName : String
    , state : PreGameState
    , error : Maybe Error
    , game : Game
    }


type alias GamePlaying =
    { game : Game
    , boxes : List Box
    , state : GameState
    , currentValue : Int
    , showGameInfo : Bool
    , error : Maybe Error
    }


type alias GameResult =
    { game : Game
    , boxes : List Box
    , state : GameResultState
    , countedPlayers : List Player
    , countedValues : List Value
    , error : Maybe Error
    }


type GameResultState
    = GameFinished
    | ShowCountedValues
    | ShowResults


type PreGameState
    = ShowAddRemovePlayers
    | ShowIndividualJoinInfo


type alias PlayerAndNumberOfValues =
    { numberOfValues : Int
    , player : Player
    }
