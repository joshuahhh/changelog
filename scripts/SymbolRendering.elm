module SymbolRendering where

import Json.Encode
import String
import Dict exposing ( Dict )
import Array exposing ( Array )

import Util exposing ( mapWhen, idIs, find, unwrapOrCrash )
import JsonEncodeUtils
import Block exposing (
  Block, BlockId, BlockBody(..), cloningToBlock, constructBlockId, jsonEncodeBlock,
  incrementNextChangeOfCloning, setRootOfCloning, appendChildToNode )
import Symbol exposing ( SymbolId, NodeId, SymbolRef(..), Cloning, Change(..), Environment )

-- And here's the dynamic world of (partially) rendered logs

type alias SymbolRendering =
  { blocks : List Block
  , rootId : Maybe BlockId
  }

type alias ChangeInContext =
  { change : Change
  , contextId : Maybe BlockId
  }

runChangeInContext : ChangeInContext -> SymbolRendering -> SymbolRendering
runChangeInContext {change, contextId} symbolRendering =
  case change of
    SetRoot cloning ->
      let
        newBlock = cloningToBlock cloning contextId
        newBlocks = newBlock ::
          case contextId of
            Just blockId ->
              mapWhen
                (idIs blockId)
                (setRootOfCloning newBlock.id)
                symbolRendering.blocks
            Nothing ->
              symbolRendering.blocks
        newRootId =
          case contextId of
            Just blockId -> symbolRendering.rootId
            Nothing -> Just cloning.id
      in
        { symbolRendering | blocks = newBlocks, rootId = newRootId }
    AppendChild nodeId cloning ->
      let
        newBlock = cloningToBlock cloning contextId
        blockIdOfParent = constructBlockId contextId nodeId
        newBlocks = newBlock ::
          mapWhen
            (idIs blockIdOfParent)
            (appendChildToNode (constructBlockId contextId cloning.id))
            symbolRendering.blocks
        newRootId = Just cloning.id
      in
        { symbolRendering | blocks = newBlocks }

incrementNextChangeOfCloningInSymbolRendering : BlockId -> SymbolRendering -> SymbolRendering
incrementNextChangeOfCloningInSymbolRendering blockId symbolRendering =
  { symbolRendering | blocks =
      symbolRendering.blocks |>
        mapWhen (idIs blockId) incrementNextChangeOfCloning
  }

catchUpCloningInSymbolRendering : Environment -> BlockId -> SymbolRendering -> SymbolRendering
catchUpCloningInSymbolRendering environment blockId symbolRendering =
  let
    block = find (idIs blockId) symbolRendering.blocks |> unwrapOrCrash (String.join "\n"
      [ "Could not find block"
      , toString blockId
      , toString (List.map .id symbolRendering.blocks)
      ])
    cloningBody =
      case block.body of
        CloningBlockBody cloningBody -> cloningBody
        _ -> Debug.crash "you can only catch up clonings!"
    nextChange = cloningBody.nextChange
    symbol = environment.symbols |> Dict.get cloningBody.symbolId |> unwrapOrCrash "Could not find symbol!"
    changes = symbol.changes
  in
    if nextChange == Array.length changes then
      -- we're caught up already!
      symbolRendering
    else
      -- catch up one change, then recurse
      symbolRendering
        |> runChangeInContext
          { change = changes |> Array.get nextChange |> unwrapOrCrash "Could not find nextChange"
          , contextId = Just blockId
          }
        |> incrementNextChangeOfCloningInSymbolRendering blockId
        |> catchUpCloningInSymbolRendering environment blockId

jsonEncodeSymbolRendering : SymbolRendering -> Json.Encode.Value
jsonEncodeSymbolRendering symbolRendering =
  let
    blockValues = List.map jsonEncodeBlock symbolRendering.blocks
  in
    Json.Encode.object
    [ ( "blocks", Json.Encode.list blockValues )
    , ( "rootId", JsonEncodeUtils.maybeString symbolRendering.rootId)
    ]
