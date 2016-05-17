module Main where

import Json.Encode
import Dict
import Array

import Util exposing ( unwrapOrCrash )
import SymbolRendering exposing (
  SymbolRendering, runChangeInContext, ChangeInContext, BlockId, BlockBody(..), Block,
  symbolRenderingToThatJsonFormatIUse, catchUpCloningInSymbolRendering)
import Symbol exposing (
  Environment, myEnvironment, Change(..), SymbolRef(..), CompoundSymbol,
  environmentToJson )


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

symbolRenderings : List SymbolRendering
symbolRenderings = List.scanl runChangeInContext initialSymbolRendering changesInContext

symbolRenderingsInJson : Json.Encode.Value
symbolRenderingsInJson = Json.Encode.list (List.map symbolRenderingToThatJsonFormatIUse symbolRenderings)
