module Main where

import Html
import Json.Encode
import Dict
import Array

import Util exposing ( unwrapOrCrash )
import SymbolRendering exposing (
  SymbolRendering, runChangeInContext, ChangeInContext, BlockId, BlockBody(..), Block,
  symbolRenderingToThatJsonFormatIUse, catchUpCloningInSymbolRendering)
import Symbol exposing ( myEnvironment, Change(..), SymbolRef(..), CompoundSymbol )


group : CompoundSymbol
group = Dict.get "Group" myEnvironment.symbols |> unwrapOrCrash "???"

transform : CompoundSymbol
transform = Dict.get "Transform" myEnvironment.symbols |> unwrapOrCrash "???"

initialSymbolRendering : SymbolRendering
initialSymbolRendering = { blocks = [], rootId = Nothing }

changesInContext : List ChangeInContext
changesInContext =
  [ { contextId = Nothing
    , change =
        SetRoot
          { id = "1"
          , symbolRef = SymbolIdAsRef "Group"
          }
    }
  , { contextId = Just "1"
    , change = Array.get 0 group.changes |> unwrapOrCrash "???"
    }
  , { contextId = Just "1"
    , change = Array.get 1 group.changes |> unwrapOrCrash "???"
    }
  , { contextId = Just "1/transform"
    , change = Array.get 0 transform.changes |> unwrapOrCrash "???"
    }
  , { contextId = Nothing
    , change =
        AppendChild
          "1/node"
          { id = "2"
          , symbolRef = SymbolIdAsRef "Group"
          }
    }
  , { contextId = Just "2"
    , change = Array.get 0 group.changes |> unwrapOrCrash "???"
    }
  , { contextId = Just "2"
    , change = Array.get 1 group.changes |> unwrapOrCrash "???"
    }
  , { contextId = Just "2/transform"
    , change = Array.get 0 transform.changes |> unwrapOrCrash "???"
    }
  , { contextId = Nothing
    , change =
        AppendChild
          "1/transform/node"
          { id = "3"
          , symbolRef = SymbolIdAsRef "Group"
          }
    }
  ]

symbolRenderings1 : List SymbolRendering
symbolRenderings1 = List.scanl runChangeInContext initialSymbolRendering changesInContext

symbolRenderingsInJson1 : Json.Encode.Value
symbolRenderingsInJson1 = Json.Encode.list (List.map symbolRenderingToThatJsonFormatIUse symbolRenderings1)

symbolRenderings2 : List SymbolRendering
symbolRenderings2 =
  let
    sr1 = { blocks = [], rootId = Nothing }
    sr2 = sr1 |> runChangeInContext
      { contextId = Nothing
      , change =
          SetRoot
            { id = "1"
            , symbolRef = SymbolIdAsRef "Group"
            }
      }
    sr3 = sr2 |> catchUpCloningInSymbolRendering myEnvironment "1"
  in
    [ sr1, sr2, sr3 ]

symbolRenderingsInJson2 : Json.Encode.Value
symbolRenderingsInJson2 = Json.Encode.list (List.map symbolRenderingToThatJsonFormatIUse symbolRenderings2)


main : Html.Html
main =
  Html.div []
    [ Html.pre [] [ Html.text (Json.Encode.encode 4 symbolRenderingsInJson2) ] ]
