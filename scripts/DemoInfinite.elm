module DemoInfinite where

import Json.Encode
import Dict
import Array

import SymbolRendering exposing (
  SymbolRendering, runChangeInContextAsStep, catchUpCloning, jsonEncodeSymbolRendering)
import Symbol exposing (
  Environment, Change(..), SymbolRef(..), environmentToJson )
import Story exposing (
  Story, emptyStory, jsonEncodeStory )

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
  emptyStory { blocks = [], rootId = Nothing }
  |> runChangeInContextAsStep
      { contextId = Nothing
      , change =
          SetRoot
            { id = "root"
            , symbolRef = SymbolIdAsRef "∞List"
            }
      }
  |> catchUpCloning myEnvironment "root"
  |> catchUpCloning myEnvironment "root/right"
  |> catchUpCloning myEnvironment "root/right/right"

storyInJson : Json.Encode.Value
storyInJson = story |> jsonEncodeStory jsonEncodeSymbolRendering

environmentInJson : Json.Encode.Value
environmentInJson = environmentToJson myEnvironment
