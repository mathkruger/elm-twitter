port module Main exposing (..)

import Browser
import Html exposing (Html, a, article, br, button, div, figure, h3, i, img, li, main_, nav, p, section, small, span, strong, text, textarea, ul)
import Html.Attributes exposing (attribute, class, placeholder, src, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode
import Json.Decode.Pipeline
import Json.Encode


port signIn : () -> Cmd msg


port signInInfo : (Json.Encode.Value -> msg) -> Sub msg


port signInError : (Json.Encode.Value -> msg) -> Sub msg


port signOut : () -> Cmd msg


port sendTweet : Json.Encode.Value -> Cmd msg


port receiveTweets : (Json.Encode.Value -> msg) -> Sub msg


port receiveLikes : (Json.Encode.Value -> msg) -> Sub msg


port deleteTweet : Json.Encode.Value -> Cmd msg


port likeTweet : ( Json.Encode.Value, Json.Encode.Value ) -> Cmd msg



---- MODEL ----


type alias Tweet =
    { uid : String
    , content : String
    , userDisplayName : String
    , userPhotoURL : String
    , userUid : String
    , date : Int
    }


type alias Like =
    { uid : String
    , tweetUid : String
    , userUid : String
    }


type alias ErrorData =
    { code : Maybe String, message : Maybe String }


type alias UserData =
    { token : String, email : String, displayName : String, photoURL : String, uid : String }


type alias Model =
    { userData : Maybe UserData, error : ErrorData, inputContent : String, tweets : List Tweet, likes : List Like }


init : ( Model, Cmd Msg )
init =
    ( { userData = Maybe.Nothing, error = emptyError, inputContent = "", tweets = [], likes = [] }, Cmd.none )



-- UPDATE


type Msg
    = LogIn
    | LogOut
    | LoggedInData (Result Json.Decode.Error UserData)
    | LoggedInError (Result Json.Decode.Error ErrorData)
    | SendTweet
    | InputChanged String
    | TweetsReceived (Result Json.Decode.Error (List Tweet))
    | LikesReceived (Result Json.Decode.Error (List Like))
    | RemoveTweet String
    | LikeTweet String String


emptyError : ErrorData
emptyError =
    { code = Maybe.Nothing, message = Maybe.Nothing }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LogIn ->
            ( model, signIn () )

        LogOut ->
            ( { model | userData = Maybe.Nothing, error = emptyError }, signOut () )

        LoggedInData result ->
            case result of
                Ok value ->
                    ( { model | userData = Just value }, Cmd.none )

                Err error ->
                    ( { model | error = messageToError <| Json.Decode.errorToString error }, Cmd.none )

        LoggedInError result ->
            case result of
                Ok value ->
                    ( { model | error = value }, Cmd.none )

                Err error ->
                    ( { model | error = messageToError (Json.Decode.errorToString error) }, Cmd.none )

        SendTweet ->
            ( { model | inputContent = "" }, sendTweet (tweetEncoder model) )

        InputChanged newValue ->
            ( { model | inputContent = newValue }, Cmd.none )

        TweetsReceived data ->
            case data of
                Ok info ->
                    ( { model | tweets = info }, Cmd.none )

                Err error ->
                    ( { model | error = messageToError (Json.Decode.errorToString error) }, Cmd.none )

        LikesReceived data ->
            case data of
                Ok info ->
                    ( { model | likes = info }, Cmd.none )

                Err error ->
                    ( { model | error = messageToError (Json.Decode.errorToString error) }, Cmd.none )

        RemoveTweet uid ->
            ( model, deleteTweet (Json.Encode.string uid) )

        LikeTweet userUid uid ->
            ( model, likeTweet ( Json.Encode.string userUid, Json.Encode.string uid ) )


messageToError : String -> ErrorData
messageToError message =
    { code = Maybe.Nothing, message = Just message }


userDataDecoder : Json.Decode.Decoder UserData
userDataDecoder =
    Json.Decode.succeed UserData
        |> Json.Decode.Pipeline.required "token" Json.Decode.string
        |> Json.Decode.Pipeline.required "email" Json.Decode.string
        |> Json.Decode.Pipeline.optional "displayName" Json.Decode.string ""
        |> Json.Decode.Pipeline.optional "photoURL" Json.Decode.string ""
        |> Json.Decode.Pipeline.required "uid" Json.Decode.string


logInErrorDecoder : Json.Decode.Decoder ErrorData
logInErrorDecoder =
    Json.Decode.succeed ErrorData
        |> Json.Decode.Pipeline.required "code" (Json.Decode.nullable Json.Decode.string)
        |> Json.Decode.Pipeline.required "message" (Json.Decode.nullable Json.Decode.string)


tweetEncoder : Model -> Json.Encode.Value
tweetEncoder model =
    Json.Encode.object
        [ ( "content", Json.Encode.string model.inputContent )
        , ( "likes", Json.Encode.int 0 )
        , ( "userDisplayName"
          , case model.userData of
                Just userData ->
                    Json.Encode.string userData.displayName

                Maybe.Nothing ->
                    Json.Encode.null
          )
        , ( "userPhotoURL"
          , case model.userData of
                Just userData ->
                    Json.Encode.string userData.photoURL

                Maybe.Nothing ->
                    Json.Encode.null
          )
        , ( "userUid"
          , case model.userData of
                Just userData ->
                    Json.Encode.string userData.uid

                Maybe.Nothing ->
                    Json.Encode.null
          )
        ]


tweetDecoder : Json.Decode.Decoder Tweet
tweetDecoder =
    Json.Decode.succeed Tweet
        |> Json.Decode.Pipeline.required "uid" Json.Decode.string
        |> Json.Decode.Pipeline.required "content" Json.Decode.string
        |> Json.Decode.Pipeline.required "userDisplayName" Json.Decode.string
        |> Json.Decode.Pipeline.required "userPhotoURL" Json.Decode.string
        |> Json.Decode.Pipeline.required "userUid" Json.Decode.string
        |> Json.Decode.Pipeline.required "date" Json.Decode.int


tweetListDecoder : Json.Decode.Decoder (List Tweet)
tweetListDecoder =
    Json.Decode.list tweetDecoder


likeDecoder : Json.Decode.Decoder Like
likeDecoder =
    Json.Decode.succeed Like
        |> Json.Decode.Pipeline.required "uid" Json.Decode.string
        |> Json.Decode.Pipeline.required "tweetUid" Json.Decode.string
        |> Json.Decode.Pipeline.required "userUid" Json.Decode.string


likeListDecoder : Json.Decode.Decoder (List Like)
likeListDecoder =
    Json.Decode.list likeDecoder



-- VIEW


getTweetLikesCount : List Like -> String -> Int
getTweetLikesCount likes tweetUid =
    List.length (List.filter (\item -> item.tweetUid == tweetUid) likes)


hasUserLikedTweet : List Like -> String -> Bool
hasUserLikedTweet likes userUid =
    List.any (\item -> item.userUid == userUid) likes


view : Model -> Html Msg
view model =
    main_ []
        [ section [ class "hero is-info" ]
            [ div [ class "hero-body" ]
                [ p [ class "title" ]
                    [ text "Elm Twitter" ]
                , p [ class "subtitle" ]
                    [ text "A simple twitter-like application written in Elm + Firebase" ]
                ]
            ]
        , div [ class "container px-4" ]
            [ case model.userData of
                Just value ->
                    loggedUserView value model

                Maybe.Nothing ->
                    div [ class "card p-4 my-4" ]
                        [ button [ class "button is-success", onClick LogIn ] [ text "Entre para começar a usar" ]
                        ]
            ]
        ]


loggedUserView : UserData -> Model -> Html Msg
loggedUserView userData model =
    div []
        [ div [ class "card p-4 my-4" ]
            [ nav [ class "level" ]
                [ div [ class "level-left" ]
                    [ p [ class "level-item" ] [ text ("Olá, " ++ userData.displayName) ]
                    ]
                , div [ class "level-right" ]
                    [ button [ class "button is-warning", onClick LogOut ] [ text "Sair" ]
                    ]
                ]
            ]
        , article [ class "media" ]
            [ figure [ class "media-left" ]
                [ p [ class "image is-64x64" ]
                    [ img [ src userData.photoURL, attribute "referrerpolicy" "no-referrer" ]
                        []
                    ]
                ]
            , div [ class "media-content" ]
                [ div [ class "field" ]
                    [ div [ class "control" ]
                        [ textarea [ class "textarea", placeholder "O que está pensando agora?", onInput InputChanged, value model.inputContent ]
                            []
                        ]
                    , div [ class "control mt-2" ]
                        [ button [ class "button is-info", onClick SendTweet ]
                            [ text "Tweetar" ]
                        ]
                    ]
                ]
            ]
        , viewTweets model.likes model.tweets userData
        ]


viewTweets : List Like -> List Tweet -> UserData -> Html Msg
viewTweets likes tweets userData =
    div []
        [ h3 [ class "is-size-3 my-4 level" ]
            [ p [ class "left-level" ] [ text "Tweets" ]
            ]
        , ul [] <|
            List.map
                (\t ->
                    li []
                        [ article [ class "media mb-4" ]
                            [ figure [ class "media-left" ]
                                [ p [ class "image is-64x64" ]
                                    [ img [ src t.userPhotoURL, attribute "referrerpolicy" "no-referrer" ]
                                        []
                                    ]
                                ]
                            , div [ class "media-content" ]
                                [ div [ class "content" ]
                                    [ p []
                                        [ strong []
                                            [ text t.userDisplayName ]
                                        , br []
                                            []
                                        , text t.content
                                        ]
                                    ]
                                , nav [ class "level is-mobile" ]
                                    [ div [ class "level-left" ]
                                        [ a
                                            [ class
                                                ("level-item "
                                                    ++ (if hasUserLikedTweet likes userData.uid == True then
                                                            "has-text-danger"

                                                        else
                                                            ""
                                                       )
                                                )
                                            , onClick (LikeTweet userData.uid t.uid)
                                            ]
                                            [ span [ class "icon is-small" ]
                                                [ i [ class "fas fa-heart" ]
                                                    []
                                                ]
                                            ]
                                        , small [] [ text (String.fromInt (getTweetLikesCount likes t.uid)) ]
                                        ]
                                    ]
                                ]
                            , if t.userUid == userData.uid then
                                div [ class "media-right" ]
                                    [ button [ class "delete", onClick (RemoveTweet t.uid) ] []
                                    ]

                              else
                                text ""
                            ]
                        ]
                )
                tweets
        ]



---- PROGRAM ----


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ signInInfo (Json.Decode.decodeValue userDataDecoder >> LoggedInData)
        , signInError (Json.Decode.decodeValue logInErrorDecoder >> LoggedInError)
        , receiveTweets (Json.Decode.decodeValue tweetListDecoder >> TweetsReceived)
        , receiveLikes (Json.Decode.decodeValue likeListDecoder >> LikesReceived)
        ]


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }
