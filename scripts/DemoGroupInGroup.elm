module DemoGroupInGroup where

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
    ( "Transform"
    , { changes = Array.fromList
        [ SetRoot (
            { id = "node"
            , symbolRef = BareNode
            }
          )
        ]
      }
    ),
    ( "Group",
      { changes = Array.fromList
        [ SetRoot (
            { id = "node"
            , symbolRef = BareNode
            }
          ),
          AppendChild "node" (
            { id = "transform"
            , symbolRef = SymbolIdAsRef "Transform"
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
            { id = "group1"
            , symbolRef = SymbolIdAsRef "Group"
            }
      }
  |> catchUpCloning myEnvironment "group1"
  |> catchUpCloning myEnvironment "group1/transform"
  |> runChangeInContextAsStep
      { contextId = Nothing
      , change =
          AppendChild
            "group1/node"
            { id = "group2"
            , symbolRef = SymbolIdAsRef "Group"
            }
      }
  |> catchUpCloning myEnvironment "group2"

storyInJson : Json.Encode.Value
storyInJson = story |> jsonEncodeStory jsonEncodeSymbolRendering

environmentInJson : Json.Encode.Value
environmentInJson = environmentToJson myEnvironment
