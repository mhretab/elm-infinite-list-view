module WithInfiniteScroll exposing (main)

import InfiniteScroll as IS
import InfiniteList as IL
import Html exposing (Html, div, p, text)
import Html.Attributes exposing (style)
import Html.Events exposing (on)
import Http
import Json.Decode as JD


type Msg
    = InfiniteScrollMsg IS.Msg
    | OnDataRetrieved (Result Http.Error (List String))
    | OnScroll JD.Value


type alias Model =
    { infScroll : IS.Model Msg
    , infList : IL.Model
    , content : List String
    }


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


initModel : Model
initModel =
    { infScroll = IS.init loadMore |> IS.offset 400 |> IS.direction IS.Bottom
    , infList = IL.init
    , content = []
    }


init : ( Model, Cmd Msg )
init =
    let
        model =
            initModel
    in
        ( { model | infScroll = IS.startLoading model.infScroll }, loadContent )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InfiniteScrollMsg msg_ ->
            let
                ( infScroll, cmd ) =
                    IS.update InfiniteScrollMsg msg_ model.infScroll
            in
                ( { model | infScroll = infScroll }, cmd )

        OnDataRetrieved (Err _) ->
            let
                infScroll =
                    IS.stopLoading model.infScroll
            in
                ( { model | infScroll = infScroll }, Cmd.none )

        OnDataRetrieved (Ok result) ->
            let
                content =
                    List.concat [ model.content, result ]

                infScroll =
                    IS.stopLoading model.infScroll
            in
                ( { model | content = content, infScroll = infScroll }, Cmd.none )

        OnScroll value ->
            let
                infList =
                    IL.updateScroll value model.infList
            in
                ( { model | infList = infList }, IS.cmdFromScrollEvent InfiniteScrollMsg value )


stringsDecoder : JD.Decoder (List String)
stringsDecoder =
    JD.list JD.string


loadContent : Cmd Msg
loadContent =
    Http.get "https://baconipsum.com/api/?type=all-meat&paras=10" stringsDecoder
        |> Http.send OnDataRetrieved


loadMore : IS.Direction -> Cmd Msg
loadMore dir =
    loadContent


itemHeight : Int
itemHeight =
    200


containerHeight : Int
containerHeight =
    500


config : IL.Config String Msg
config =
    IL.config
        { itemView = itemView
        , itemHeight = IL.constantHeight itemHeight
        , containerHeight = containerHeight
        }


itemView : Int -> Int -> String -> Html Msg
itemView idx listIdx item =
    p
        [ style
            [ ( "height", (toString itemHeight) ++ "px" )
            , ( "overflow", "hidden" )
            , ( "margin", "0" )
            ]
        ]
        [ text item ]


view : Model -> Html Msg
view model =
    div
        [ style
            [ ( "height", "500px" )
            , ( "width", "500px" )
            , ( "overflow", "auto" )
            , ( "border", "1px solid #000" )
            , ( "margin", "auto" )
            ]
        , on "scroll" (JD.map OnScroll JD.value)
        ]
        ((IL.view config model.infList model.content) :: loader model)


loader : Model -> List (Html Msg)
loader { infScroll } =
    if IS.isLoading infScroll then
        [ div
            [ style
                [ ( "color", "red" )
                , ( "font-weight", "bold" )
                , ( "text-align", "center" )
                ]
            ]
            [ text "Loading ..." ]
        ]
    else
        []


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
