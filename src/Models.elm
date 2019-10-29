module Models exposing (BlurredModel(..), GameAndUserId, MarkedPlayer(..), Mode(..), Model, Msg(..))

import Json.Decode exposing (Decoder, field, int, map3, string)
import Model.Box exposing (Box)
import Model.Error exposing (Error(..))
import Model.Game exposing (DbGame, Game)
import Model.GameState exposing (GameState)
import Model.GlobalHighscore exposing (GlobalHighscore)
import Model.GlobalHighscoreItem exposing (GlobalHighscoreItem)
import Model.Player exposing (Player)
import Model.User exposing (User)
import Model.Value exposing (Value)
import Model.WindowState exposing (WindowState)
import Time


type Msg
    = ShowStartPage
    | ChangeActiveHighscoreTab Int
    | CreateGame
    | JoinExistingGame
    | EnterGame
    | ShowSelectPlayer
    | PlayerMarked Player
    | AllPlayersMarked
    | AddRemovePlayers
    | CreateUser
    | RemoteUsers (List User)
    | RemoteValuesReceived (List Value)
    | GameReceived Game
    | GamesReceived (List Game)
    | GlobalHighscoreReceived (List GlobalHighscore)
    | WindowFocusedReceived Game String
    | WindowBlurredReceived
    | AddPlayer User
    | RemovePlayer User
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
    | ShowGameHighscore
    | HideGameHighscore
    | CountValues
    | CountValuesTick Time.Posix
    | HideHighscore
    | Restart
    | HideNotification
    | ShowGameInfo
    | ReloadGame
    | HideGameInfo
    | FillWithDummyValues Player
    | NoOp



-- type Error a b
--     = Just a b
--     | Nothing


type alias Model =
    { mode : Mode
    , users : List User
    , games : List Game
    , highscoreList : List GlobalHighscore
    , windowState : WindowState
    , isAdmin : Bool
    }


type Mode
    = StartPage Int
    | ShowAddRemovePlayers (List User) String
    | EnterGameCode String
    | WaitForGame Bool
    | ShowGameCode Game
    | SelectPlayer Game MarkedPlayer
    | Playing Game MarkedPlayer GameState Int Bool
    | ShowGameFinished Game MarkedPlayer
    | ShowGameResults Game MarkedPlayer
    | ShowFinishedScoreCard Game MarkedPlayer Bool
    | BlurredGame BlurredModel


type MarkedPlayer
    = Single Player
    | All
    | NoPlayer


type BlurredModel
    = Reconnecting Game String
    | Inactive



-- type Mode
--     = StartPage Int
--     | Individual IndividualModel
--     | Group GroupModel
--     | BlurredGame BlurredModel
--
-- type IndividualModel
--     = EnterGameCode String (List Game)
--     | WaitingForGame
--     | SelectPlayer MarkedPlayer
--     | IndividualPlaying IndividualPlayingModel
--     | IndividualPostGame IndividualPostGameModel
-- type GroupModel
--     = PreGame GameSetup
--     | Playing GamePlaying
--     | PostGame GameResult
--
-- type alias IndividualPlayingModel =
--     { gamePlaying : GamePlaying
--     , selectedPlayer : Player
--     }
--
--
-- type alias IndividualPostGameModel =
--     { selectedPlayer : Player
--     }
-- type alias ShowAddRemovePlayers =
--     { players : List Player
--     , currentNewPlayerName : String
--     }
--
--
-- type alias GamePlaying =
--     { boxes : List Box
--     , state : GameState
--     , currentValue : Int
--     , showGameInfo : Bool
--     , error : Maybe Error
--     }
-- type alias GameResult =
--     { boxes : List Box
--     , state : GameResultState
--     , countedPlayers : List Player
--     , countedValues : List Value
--     , showGameInfo : Bool
--     , error : Maybe Error
--     }
-- type GameResultState
--     = GameFinished
--     | ShowCountedValues
--     | ShowResults
--     | HideResults
-- type PreGameState
--     = ShowAddRemovePlayers
--     | ShowIndividualJoinInfo


type alias PlayerAndNumberOfValues =
    { numberOfValues : Int
    , player : Player
    }


type alias GameAndUserId =
    { game : DbGame
    , userId : String
    }
