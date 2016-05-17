module SymbolRendering where

import Json.Encode
import String
import Dict exposing ( Dict )
import Array exposing ( Array )

import Util exposing ( mapWhen, idIs, find, unwrapOrCrash )
import JsonEncodeTools exposing ( jsonEncodeMaybeString )
import Symbol exposing ( SymbolId, NodeId, SymbolRef(..), Cloning, Change(..), Environment )

-- And here's the dynamic world of (partially) rendered logs

type alias SymbolRendering =
  { blocks : List Block
  , rootId : Maybe BlockId
  }

type alias BlockId = String

type alias Block =
  { id : BlockId
  , localId : BlockId
  , ownerId : Maybe BlockId
  , body : BlockBody
  }

type BlockBody = NodeBodyAsBlockBody NodeBody | CloningBodyAsBlockBody CloningBody

type alias NodeBody =
  { childIds: List BlockId }

type alias CloningBody =
  { rootId: Maybe BlockId, symbolId: SymbolId, nextChange: Int }

constructBlockId : Maybe BlockId -> NodeId -> BlockId
constructBlockId maybeBlockId nodeId =
  case maybeBlockId of
    Just blockId -> blockId ++ "/" ++ nodeId
    Nothing -> nodeId

cloningToBlock : Cloning -> Maybe BlockId -> Block
cloningToBlock cloning maybeOwnerId =
  let
    newId = constructBlockId maybeOwnerId cloning.id
    newBody = case cloning.symbolRef of
      BareNode ->
        NodeBodyAsBlockBody { childIds = [] }
      SymbolIdAsRef symbolId ->
        CloningBodyAsBlockBody { rootId = Nothing, symbolId = symbolId, nextChange = 0 }
  in
    Block newId cloning.id maybeOwnerId newBody

appendChildToBlockWhichMustBeNode : BlockId -> Block -> Block
appendChildToBlockWhichMustBeNode childId block =
  let
    oldNodeBody = case block.body of
      NodeBodyAsBlockBody oldNodeBody -> oldNodeBody
      _ -> Debug.crash "you can only add a child to a node!"
    newBody = NodeBodyAsBlockBody { oldNodeBody | childIds = List.append oldNodeBody.childIds [childId] }
  in
    { block | body = newBody }

setRootOfBlockWhichMustBeCloning : BlockId -> Block -> Block
setRootOfBlockWhichMustBeCloning rootId block =
  let
    oldCloningBody = case block.body of
      CloningBodyAsBlockBody oldCloningBody -> oldCloningBody
      _ -> Debug.crash "you can only set the root of a cloning!"
    newBody = CloningBodyAsBlockBody { oldCloningBody | rootId = Just rootId }
  in
    { block | body = newBody }

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
                (setRootOfBlockWhichMustBeCloning newBlock.id)
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
            (appendChildToBlockWhichMustBeNode (constructBlockId contextId cloning.id))
            symbolRendering.blocks
        newRootId = Just cloning.id
      in
        { symbolRendering | blocks = newBlocks }

incrementNextChangeOfBlockWhichMustBeCloning : Block -> Block
incrementNextChangeOfBlockWhichMustBeCloning block =
  let
    oldCloningBody = case block.body of
      CloningBodyAsBlockBody oldCloningBody -> oldCloningBody
      _ -> Debug.crash "you can only increment `nextChange` of a cloning!"
    newBody = CloningBodyAsBlockBody { oldCloningBody | nextChange = oldCloningBody.nextChange + 1 }
  in
    { block | body = newBody }

incrementNextChangeOfCloningInSymbolRendering : BlockId -> SymbolRendering -> SymbolRendering
incrementNextChangeOfCloningInSymbolRendering blockId symbolRendering =
  { symbolRendering | blocks =
      symbolRendering.blocks |>
        mapWhen (idIs blockId) incrementNextChangeOfBlockWhichMustBeCloning
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
        CloningBodyAsBlockBody cloningBody -> cloningBody
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

type ExtractedNode =
  ExtractedNode { id : BlockId, children : List ExtractedNode }

extractNodes : SymbolRendering -> Maybe ExtractedNode
extractNodes { blocks, rootId } =
  case rootId of
    Just rootId -> extractNodesFromRoot blocks rootId
    Nothing -> Nothing

extractNodesFromRoot : List Block -> BlockId -> Maybe ExtractedNode
extractNodesFromRoot blocks rootId =
  let
    rootBlock = find (idIs rootId) blocks |> unwrapOrCrash "Could not find root block"
  in
    case rootBlock.body of
      CloningBodyAsBlockBody cloningBody ->
        case cloningBody.rootId of
          Just rootId -> extractNodesFromRoot blocks rootId
          Nothing -> Nothing
      NodeBodyAsBlockBody blockBody ->
        Just (ExtractedNode
          { id = rootBlock.id
          , children = List.filterMap (extractNodesFromRoot blocks) blockBody.childIds })

jsonEncodeBlock : Block -> Json.Encode.Value
jsonEncodeBlock {id, localId, ownerId, body} =
  Json.Encode.object (
    [ ( "id", Json.Encode.string id )
    , ( "localId", Json.Encode.string localId )
    , ( "ownerId", jsonEncodeMaybeString ownerId )
    ] ++
    case body of
      NodeBodyAsBlockBody { childIds } ->
        [ ( "type", Json.Encode.string "node" )
        , ( "childIds", Json.Encode.list (List.map Json.Encode.string childIds) )
        ]
      CloningBodyAsBlockBody { rootId, symbolId, nextChange } ->
        [ ( "type", Json.Encode.string "cloning" )
        , ( "rootId", jsonEncodeMaybeString rootId )
        , ( "symbolId", Json.Encode.string symbolId )
        , ( "nextChange", Json.Encode.int nextChange )
        ])


jsonEncodeSymbolRendering : SymbolRendering -> Json.Encode.Value
jsonEncodeSymbolRendering symbolRendering =
  let
    blockValues = List.map jsonEncodeBlock symbolRendering.blocks
  in
    Json.Encode.object
    [ ( "blocks", Json.Encode.list blockValues )
    , ( "rootId", jsonEncodeMaybeString symbolRendering.rootId)
    ]
