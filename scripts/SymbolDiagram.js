// import _ from 'underscore';
import update from 'react-addons-update';


export class SymbolDiagram {
  constructor(nodes, clonings, rootCloningId) {
    this.nodes = nodes;
    this.clonings = clonings;
    this.rootCloningId = rootCloningId;
  }

  clone(cloningId) {
    const idFunc = (id) => id ? cloningId + '/' + id : cloningId;

    const newRootCloning = {
      id: cloningId,
      rootId: idFunc(this.rootCloningId),
      ownerId: null
    };

    const newNodes = this.nodes.map((node) =>
      update(node, {id: {$apply: idFunc}, childIds: {$apply: (l) => l.map(idFunc)}})
    );
    const newClonings = this.clonings.map((node) =>
      update(node, {id: {$apply: idFunc}, rootId: {$apply: idFunc}, ownerId: {$apply: idFunc}})
    ).concat([newRootCloning]);
    return new SymbolDiagram(newNodes, newClonings, newRootCloning.id);
  }

  appendChild(parentId, child) {
    const newNodes = this.nodes.map((node) => {
      if (node.id == parentId) {
        return update(node, {childIds: {$push: [child.rootCloningId]}});
      } else {
        return node;
      }
    }).concat(child.nodes);
    const newClonings = this.clonings.concat(child.clonings);
    return new SymbolDiagram(newNodes, newClonings, this.rootCloningId);
  }
}

export const node =
  new SymbolDiagram([{id: 'node', childIds: []}], [], 'node');

export const attribute =
  node.clone('attribute');

export const transform =
  node.clone('transform')
  .appendChild('transform/node', attribute.clone('transform-attribute'));

export const group =
  node.clone('group')
  .appendChild('group/node', transform.clone('group-transform'));
