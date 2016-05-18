module Block (
  Block, BlockId, BlockBody(..), cloningToBlock, constructBlockId, jsonEncodeBlock,
  incrementNextChangeOfCloning, setRootOfCloning, appendChildToNode ) where

import Json.Encode
import JsonEncodeUtils
import Symbol

import Symbol

-- And here's the dynamic world of (partially) rendered logs

type alias BlockId = String

type alias Block =
  { id : BlockId
  , localId : BlockId
  , ownerId : Maybe BlockId
  , body : BlockBody
  }

type BlockBody = NodeBlockBody NodeBody | CloningBlockBody CloningBody

type alias NodeBody =
  { childIds: List BlockId }

type alias CloningBody =
  { rootId: Maybe BlockId, symbolId: Symbol.SymbolId, nextChange: Int }

constructBlockId : Maybe BlockId -> Symbol.NodeId -> BlockId
constructBlockId maybeBlockId nodeId =
  case maybeBlockId of
    Just blockId -> blockId ++ "/" ++ nodeId
    Nothing -> nodeId

cloningToBlock : Symbol.Cloning -> Maybe BlockId -> Block
cloningToBlock cloning maybeOwnerId =
  let
    newId = constructBlockId maybeOwnerId cloning.id
    newBody = case cloning.symbolRef of
      Symbol.BareNode ->
        NodeBlockBody { childIds = [] }
      Symbol.SymbolIdAsRef symbolId ->
        CloningBlockBody { rootId = Nothing, symbolId = symbolId, nextChange = 0 }
  in
    Block newId cloning.id maybeOwnerId newBody

appendChildToNode : BlockId -> Block -> Block
appendChildToNode childId block =
  let
    oldNodeBody = case block.body of
      NodeBlockBody oldNodeBody -> oldNodeBody
      _ -> Debug.crash "you can only add a child to a node!"
    newBody = NodeBlockBody { oldNodeBody | childIds = List.append oldNodeBody.childIds [childId] }
  in
    { block | body = newBody }

setRootOfCloning : BlockId -> Block -> Block
setRootOfCloning rootId block =
  let
    oldCloningBody = case block.body of
      CloningBlockBody oldCloningBody -> oldCloningBody
      _ -> Debug.crash "you can only set the root of a cloning!"
    newBody = CloningBlockBody { oldCloningBody | rootId = Just rootId }
  in
    { block | body = newBody }

type alias ChangeInContext =
  { change : Symbol.Change
  , contextId : Maybe BlockId
  }

incrementNextChangeOfCloning : Block -> Block
incrementNextChangeOfCloning block =
  let
    oldCloningBody = case block.body of
      CloningBlockBody oldCloningBody -> oldCloningBody
      _ -> Debug.crash "you can only increment `nextChange` of a cloning!"
    newBody = CloningBlockBody { oldCloningBody | nextChange = oldCloningBody.nextChange + 1 }
  in
    { block | body = newBody }

jsonEncodeBlock : Block -> Json.Encode.Value
jsonEncodeBlock {id, localId, ownerId, body} =
  Json.Encode.object (
    [ ( "id", Json.Encode.string id )
    , ( "localId", Json.Encode.string localId )
    , ( "ownerId", JsonEncodeUtils.maybeString ownerId )
    ] ++
    case body of
      NodeBlockBody { childIds } ->
        [ ( "type", Json.Encode.string "node" )
        , ( "childIds", Json.Encode.list (List.map Json.Encode.string childIds) )
        ]
      CloningBlockBody { rootId, symbolId, nextChange } ->
        [ ( "type", Json.Encode.string "cloning" )
        , ( "rootId", JsonEncodeUtils.maybeString rootId )
        , ( "symbolId", Json.Encode.string symbolId )
        , ( "nextChange", Json.Encode.int nextChange )
        ])
