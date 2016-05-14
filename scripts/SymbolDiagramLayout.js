/* global c */

import {Box, addPseudoQuadraticToObjective, addAbsoluteValueToObjective} from './Constraints';
import _ from 'underscore';

const options = {
  nodeWidth: 60,
  nodeHeight: 30,
  cloningLabelWidth: 150,
  verticalSpacing: 10,
  paddingBetweenClonings: 10,
};

export class SymbolDiagramLayout {
  constructor(symbolDiagram) {
    _.extend(this, _.pick(symbolDiagram, 'nodes', 'clonings', 'rootCloningId'));
    this.nodesById = _.indexBy(this.nodes, 'id');
    this.cloningsById = _.indexBy(this.clonings, 'id');
    this.cloningsByRootId = _.indexBy(this.clonings, 'rootId');

    this.nodes.forEach((node) => {
      node.box = new Box(node.id, {width: options.nodeWidth, height: options.nodeHeight});
      node.subtreeLeft = new c.Variable();
      node.subtreeRight = new c.Variable();
    });

    this.clonings.forEach((cloning) => {
      cloning.innerBox = new Box(cloning.id);
      cloning.outerBox = new Box(cloning.id);

      var rootChain = cloning;
      while (this.cloningsById[rootChain.rootId]) {
        rootChain = this.cloningsById[rootChain.rootId];
      }
      cloning.underlyingNodeId = rootChain.rootId || rootChain.id;
    });
  }

  resolve() {
    var solver = new c.SimplexSolver();
    var objectiveExpression = new c.Expression(0);

    const eq = (x, y) => solver.addConstraint(new c.Equation(x, y));
    const ineq = (x, r, y) => solver.addConstraint(new c.Inequality(x, r, y));

    this.clonings.forEach((cloning) => {
      cloning.innerBox.constrain(solver);
      cloning.outerBox.constrain(solver);

      ineq(cloning.innerBox.width, c.GEQ, options.nodeWidth);
      ineq(cloning.innerBox.height, c.GEQ, options.nodeHeight);


      objectiveExpression = objectiveExpression.plus(cloning.innerBox.width);

      ineq(cloning.outerBox.left, c.GEQ, 20);
      ineq(cloning.outerBox.top, c.GEQ, 20);

      eq(cloning.innerBox.left, cloning.outerBox.left);
      eq(cloning.innerBox.top, cloning.outerBox.top);
      eq(cloning.innerBox.bottom, cloning.outerBox.bottom);
      const cloningLabelWidth = 10 + cloning.id.length * 4;
      eq(c.plus(cloning.innerBox.right, cloningLabelWidth), cloning.outerBox.right);

      const rootCloning = this.cloningsById[cloning.rootId];
      if (rootCloning) {
        eq(cloning.innerBox.top, rootCloning.innerBox.top);
        // eq(cloning.innerBox.centerX, rootCloning.innerBox.centerX);
      } else {
        const rootNode = this.nodesById[cloning.rootId];
        if (rootNode) {
          eq(cloning.innerBox.top, rootNode.box.top);
          // eq(cloning.innerBox.centerX, rootNode.box.centerX);
          ineq(rootNode.box.left, c.GEQ, c.plus(cloning.innerBox.left, options.paddingBetweenClonings));
          ineq(rootNode.box.right, c.LEQ, c.plus(cloning.innerBox.right, -options.paddingBetweenClonings));
          ineq(rootNode.box.bottom, c.LEQ, c.plus(cloning.innerBox.bottom, -options.paddingBetweenClonings));
        }
      }

      const ownerCloning = this.cloningsById[cloning.ownerId];
      if (ownerCloning) {
        ineq(cloning.outerBox.top, c.GEQ, ownerCloning.innerBox.top);
        ineq(cloning.outerBox.left, c.GEQ, c.plus(ownerCloning.innerBox.left, options.paddingBetweenClonings));
        ineq(cloning.outerBox.right, c.LEQ, c.plus(ownerCloning.innerBox.right, -options.paddingBetweenClonings));
        ineq(cloning.outerBox.bottom, c.LEQ, c.plus(ownerCloning.innerBox.bottom, -options.paddingBetweenClonings));
      }
    });

    this.nodes.forEach((node) => {
      node.box.constrain(solver);

      eq(node.box.width, options.nodeWidth);
      eq(node.box.height, options.nodeHeight);

      ineq(node.box.left, c.GEQ, 20);
      ineq(node.box.top, c.GEQ, 20);


      var lastChild = null;
      node.childIds.forEach((childId) => {
        const child = this.cloningsById[childId];

        ineq(c.plus(node.box.bottom, 2 * options.verticalSpacing), c.LEQ, child.outerBox.top);
        objectiveExpression = objectiveExpression.plus(c.minus(child.outerBox.top, node.box.bottom));

        console.log(child.id, child.underlyingNodeId);
        const underlyingNode = this.nodesById[child.underlyingNodeId];
        if (underlyingNode) {
          objectiveExpression = addPseudoQuadraticToObjective(
            objectiveExpression,
            node.box.centerX, underlyingNode.box.centerX, solver, 600, 50);
        } else {
          const underlyingCloning = this.cloningsById[child.underlyingNodeId];
          objectiveExpression = addPseudoQuadraticToObjective(
            objectiveExpression,
            node.box.centerX, underlyingCloning.innerBox.centerX, solver, 600, 50);
        }

        // Climb up the parent's owner hierarchy.
        var ownerChain = this.cloningsByRootId[node.id];
        while (ownerChain && child.ownerId !== ownerChain.id) {
          ineq(c.plus(ownerChain.outerBox.bottom, options.verticalSpacing * 5), c.LEQ, child.outerBox.top);
          ownerChain = this.cloningsById[ownerChain.ownerId];
        }

        if (lastChild) {
          ineq(child.outerBox.left, c.GEQ, c.plus(lastChild.outerBox.right, 10));
        }
        lastChild = child;
      });
    });

    var objectiveVariable = new c.Variable();
    solver.addConstraint(new c.Equation(objectiveVariable, objectiveExpression));
    window.objectiveVariable = objectiveVariable;
    window.objectiveExpression = objectiveExpression;
    solver.optimize(objectiveVariable);
    solver.resolve();
  }
}
