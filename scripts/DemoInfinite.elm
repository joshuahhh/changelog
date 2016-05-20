module DemoInfinite where

import Json.Encode
import Dict
import Array

import SymbolRendering exposing (
  SymbolRendering, runChangeInContextAsStep, catchUpCloning, jsonEncodeSymbolRendering)
import Symbol exposing (
  Environment, Change(..), SymbolRef(..), environmentToJson )
import Story exposing ( Story )

myEnvironment : Environment
myEnvironment =
  { symbols = Dict.fromList [
    ( "∞List"
    , { changes = Array.fromList
        [ SetRoot (
            { id = "pair"
            , symbolRef = BareNode
            }
          ),
          AppendChild "pair" (
            { id = "left"
            , symbolRef = BareNode
            }
          ),
          AppendChild "pair" (
            { id = "right"
            , symbolRef = SymbolIdAsRef "∞List"
            }
          )
        ]
      }
    )
  ]}

story : Story SymbolRendering
story =
  Story.start { blocks = [], rootId = Nothing }
  |> runChangeInContextAsStep
      { contextId = Nothing
      , change =
          SetRoot
            { id = "myRoot"
            , symbolRef = SymbolIdAsRef "∞List"
            }
      }
      myEnvironment
  |> catchUpCloning "myRoot" myEnvironment
  |> catchUpCloning "myRoot/right" myEnvironment
  |> catchUpCloning "myRoot/right/right" myEnvironment

storyInJson : Json.Encode.Value
storyInJson = story |> Story.jsonEncodeStory jsonEncodeSymbolRendering

environmentInJson : Json.Encode.Value
environmentInJson = environmentToJson myEnvironment
