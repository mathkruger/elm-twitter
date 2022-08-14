port module Main exposing (..)

import Browser
import Html exposing (Html, article, button, div, figure, img, main_, nav, p, section, text, textarea)
import Html.Attributes exposing (class, placeholder, src, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode
import Json.Decode.Pipeline
import Json.Encode


port signIn : () -> Cmd msg


port signInInfo : (Json.Encode.Value -> msg) -> Sub msg


port signInError : (Json.Encode.Value -> msg) -> Sub msg


port signOut : () -> Cmd msg


port saveMessage : Json.Encode.Value -> Cmd msg


port receiveMessages : (Json.Encode.Value -> msg) -> Sub msg



---- MODEL ----


type alias Message =
    { uid : String, content : String, userEmail : String }


type alias ErrorData =
    { code : Maybe String, message : Maybe String, credential : Maybe String }


type alias UserData =
    { token : String, email : String, displayName : String, photoURL : String, uid : String }


type alias Model =
    { userData : Maybe UserData, error : ErrorData, inputContent : String, messages : List Message }


init : ( Model, Cmd Msg )
init =
    ( { userData = Maybe.Nothing, error = emptyError, inputContent = "", messages = [] }, Cmd.none )



-- UPDATE


type Msg
    = LogIn
    | LogOut
    | LoggedInData (Result Json.Decode.Error UserData)
    | LoggedInError (Result Json.Decode.Error ErrorData)
    | SaveMessage
    | InputChanged String
    | MessagesReceived (Result Json.Decode.Error (List Message))


emptyError : ErrorData
emptyError =
    { code = Maybe.Nothing, credential = Maybe.Nothing, message = Maybe.Nothing }


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
                    ( { model | error = messageToError <| Json.Decode.errorToString error }, Cmd.none )

        SaveMessage ->
            Debug.todo "branch 'SaveMessage' not implemented"

        InputChanged _ ->
            Debug.todo "branch 'InputChanged _' not implemented"

        MessagesReceived _ ->
            Debug.todo "branch 'MessagesReceived _' not implemented"


messageToError : String -> ErrorData
messageToError message =
    { code = Maybe.Nothing, credential = Maybe.Nothing, message = Just message }


userDataDecoder : Json.Decode.Decoder UserData
userDataDecoder =
    Json.Decode.succeed UserData
        |> Json.Decode.Pipeline.required "token" Json.Decode.string
        |> Json.Decode.Pipeline.required "email" Json.Decode.string
        |> Json.Decode.Pipeline.optional "displayName" Json.Decode.string ""
        |> Json.Decode.Pipeline.optional "photoUrl" Json.Decode.string ""
        |> Json.Decode.Pipeline.required "uid" Json.Decode.string


logInErrorDecoder : Json.Decode.Decoder ErrorData
logInErrorDecoder =
    Json.Decode.succeed ErrorData
        |> Json.Decode.Pipeline.required "code" (Json.Decode.nullable Json.Decode.string)
        |> Json.Decode.Pipeline.required "message" (Json.Decode.nullable Json.Decode.string)
        |> Json.Decode.Pipeline.required "credential" (Json.Decode.nullable Json.Decode.string)



-- VIEW


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
                    loggedUserView value

                Maybe.Nothing ->
                    button [ class "button is-success", onClick LogIn ] [ text "Entre para começar a usar" ]
            ]
        ]


loggedUserView : UserData -> Html Msg
loggedUserView userData =
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
                    [ img [ src userData.photoURL ]
                        []
                    ]
                ]
            , div [ class "media-content" ]
                [ div [ class "field" ]
                    [ p [ class "control" ]
                        [ textarea [ class "textarea", placeholder "Add a comment..." ]
                            []
                        ]
                    ]
                , nav [ class "level" ]
                    [ div [ class "level-left" ]
                        [ div [ class "level-item" ]
                            [ button [ class "button is-info" ]
                                [ text "Submit" ]
                            ]
                        ]
                    ]
                ]
            ]
        ]



---- PROGRAM ----


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ signInInfo (Json.Decode.decodeValue userDataDecoder >> LoggedInData)
        , signInError (Json.Decode.decodeValue logInErrorDecoder >> LoggedInError)

        -- , receiveMessages (Json.Decode.decodeValue messageListDecoder >> MessagesReceived)
        ]


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }
