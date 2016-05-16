module Main where

import Html
import Json.Encode
import Dict
import Array

import Util exposing ( force )
import SymbolRendering exposing (
  SymbolRendering, runChangeInContext, ChangeInContext, BlockId, BlockBody(..), Block,
  symbolRenderingToThatJsonFormatIUse)
import Symbol exposing ( myEnvironment, Change(..), SymbolRef(..), CompoundSymbol )


group : CompoundSymbol
group = force (Dict.get "Group" myEnvironment.symbols)

transform : CompoundSymbol
transform = force (Dict.get "Transform" myEnvironment.symbols)

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
    , change = force (Array.get 0 group.changes)
    }
  , { contextId = Just "1"
    , change = force (Array.get 1 group.changes)
    }
  , { contextId = Just "1/transform"
    , change = force (Array.get 0 transform.changes)
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
    , change = force (Array.get 0 group.changes)
    }
  , { contextId = Just "2"
    , change = force (Array.get 1 group.changes)
    }
  , { contextId = Just "2/transform"
    , change = force (Array.get 0 transform.changes)
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

main : Html.Html
main =
  Html.div []
    [ Html.pre [] [ Html.text (Json.Encode.encode 4 symbolRenderingsInJson) ] ]
    -- (List.map
    --   (\j -> Html.pre [] [ Html.text (Json.Encode.encode 4 j) ])
    --   symbolRenderingsInJson)
