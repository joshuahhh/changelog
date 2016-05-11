/* global c */

import {Box, addPseudoQuadraticToObjective, addAbsoluteValueToObjective} from './Constraints';
import _ from 'underscore';

// Constraints:
// * Each box has a fixed size
// * Each box is a certain distance below its parent
// * Each box is a certain distance away from its neighbors in its row
// * Each box is in the field
// Objectives:
// * Each box is horizontally as close as possible to its parent

export class TreeLayout {
  constructor(tree) {
    this.boxesById = {};
    this.cloningBoxesById = {};

    this.addSubtree(tree.rootNode, null);
    tree.clonings.forEach((cloning) => this.addCloning(cloning));
  }

  addSubtree(subtree, parentId) {
    var box = new Box(subtree.id, {width: 200, height: 100});
    box.id = subtree.id;
    box.parentId = parentId;
    box.cloningId = subtree.cloningId;
    box.subtreeLeft = new c.Variable({});
    box.subtreeRight = new c.Variable({});

    this.boxesById[box.id] = box;
    box.childIds = (subtree.children || []).map((child) =>
      this.addSubtree(child, box.id)
    );

    return box.id;
  }

  addCloning(cloning) {
    var box = new Box(cloning.id, {width: 200, height: 100});
    box.id = cloning.id;
    box.name = cloning.name;
    box.parentId = cloning.parentId;

    this.cloningBoxesById[box.id] = box;
  }

  resolve() {
    var solver = new c.SimplexSolver();

    var objectiveExpression = new c.Expression(0);

    _.each(this.boxesById, (box) => {
      box.getConstraints().forEach((constraint) => solver.addConstraint(constraint));
      solver.addConstraint(new c.Equation(box.width, 100));
      solver.addConstraint(new c.Equation(box.height, 50));
      solver.addConstraint(new c.Inequality(box.left, c.GEQ, 20));
      solver.addConstraint(new c.Inequality(box.top, c.GEQ, 20));

      if (box.parentId) {
        const parentBox = this.boxesById[box.parentId];
        // Vertical constraint
        solver.addConstraint(new c.Inequality(box.top, c.GEQ, c.plus(parentBox.bottom, 50)));
        objectiveExpression = objectiveExpression.plus(c.minus(box.top, parentBox.bottom));
        // Horizontal objective
        // objectiveExpression = addAbsoluteValueToObjective(objectiveExpression, box.centerX, parentBox.centerX, solver);
        objectiveExpression = addPseudoQuadraticToObjective(objectiveExpression, box.centerX, parentBox.centerX, solver, 600, 50);

        solver.addConstraint(new c.Inequality(parentBox.subtreeLeft, c.LEQ, box.subtreeLeft));
        solver.addConstraint(new c.Inequality(box.subtreeRight, c.LEQ, parentBox.subtreeRight));

        solver.addConstraint(new c.Inequality(box.subtreeLeft, c.LEQ, box.left));
        solver.addConstraint(new c.Inequality(box.right, c.LEQ, box.subtreeRight));

        if (parentBox.cloningId) {
          if (box.cloningId && (box.cloningId == parentBox.cloningId || this.cloningBoxesById[box.cloningId].parentId == parentBox.cloningId)) {
            // everything's ok
          } else {
            solver.addConstraint(new c.Inequality(box.top, c.GEQ, c.plus(this.cloningBoxesById[parentBox.cloningId].bottom, 20)));
          }
        }
      }

      if (box.cloningId) {
        const cloningBox = this.cloningBoxesById[box.cloningId];
        box.constrainToBeInside(cloningBox, 10, solver);
      }

      var lastBox = null;
      box.childIds.forEach((childId) => {
        const childBox = this.boxesById[childId];
        if (lastBox) {
          solver.addConstraint(new c.Inequality(childBox.subtreeLeft, c.GEQ, c.plus(lastBox.subtreeRight, 20)));
        }
        lastBox = childBox;

        if (box.cloningId) {
          const cloningBox = this.cloningBoxesById[box.cloningId];
          solver.addConstraint(new c.Inequality(cloningBox.left, c.LEQ, c.plus(childBox.centerX, -30)));
          solver.addConstraint(new c.Inequality(c.plus(childBox.centerX, 30), c.LEQ, cloningBox.right));
        }
      });
    });

    _.each(this.cloningBoxesById, (box) => {
      box.getConstraints().forEach((constraint) => solver.addConstraint(constraint));

      if (box.parentId) {
        const parentBox = this.cloningBoxesById[box.parentId];
        box.constrainToBeInside(parentBox, 10, solver);
      }
    });


    var objectiveVariable = new c.Variable();
    solver.addConstraint(new c.Equation(objectiveVariable, objectiveExpression));
    window.objectiveVariable = objectiveVariable;
    window.objectiveExpression = objectiveExpression;
    solver.optimize(objectiveVariable);
    solver.resolve();

  }
}
