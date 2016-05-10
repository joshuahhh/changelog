import {Box, addAbsoluteValueToObjective, addPseudoQuadraticToObjective} from './Constraints';
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

    this.addSubtree(tree, null);
  }

  addSubtree(subtree, parentId) {
    var box = new Box(subtree.id, {width: 200, height: 100});
    box.id = subtree.id;
    box.parentId = parentId;
    box.subtreeLeft = new c.Variable({});
    box.subtreeRight = new c.Variable({});

    this.boxesById[box.id] = box;
    box.childIds = (subtree.children || []).map((child) =>
      this.addSubtree(child, box.id)
    );

    return box.id;
  }

  resolve() {
    var solver = new c.SimplexSolver();

    var objectiveExpression = new c.Expression(0);

    _.each(this.boxesById, (box) => {
      box.getConstraints().forEach((constraint) => solver.addConstraint(constraint));
      solver.addConstraint(new c.Equation(box.width, 100));
      solver.addConstraint(new c.Equation(box.height, 50));
      solver.addConstraint(new c.Inequality(box.left, c.GEQ, 10));
      solver.addConstraint(new c.Inequality(box.top, c.GEQ, 10));

      if (box.parentId) {
        const parentBox = this.boxesById[box.parentId];
        // Vertical constraint
        solver.addConstraint(new c.Equation(box.top, c.plus(parentBox.bottom, 30)));
        // Horizontal objective
        // objectiveExpression = addAbsoluteValueToObjective(objectiveExpression, box.centerX, box.parentBox.centerX, solver);
        objectiveExpression = addPseudoQuadraticToObjective(objectiveExpression, box.centerX, parentBox.centerX, solver, 600, 200);

        solver.addConstraint(new c.Inequality(parentBox.subtreeLeft, c.LEQ, box.subtreeLeft));
        solver.addConstraint(new c.Inequality(box.subtreeRight, c.LEQ, parentBox.subtreeRight));

        solver.addConstraint(new c.Inequality(box.subtreeLeft, c.LEQ, box.left));
        solver.addConstraint(new c.Inequality(box.right, c.LEQ, box.subtreeRight));
      }

      var lastBox = null;
      box.childIds.forEach((childId) => {
        box = this.boxesById[childId];
        if (lastBox) {
          solver.addConstraint(new c.Inequality(box.subtreeLeft, c.GEQ, c.plus(lastBox.subtreeRight, 10)));
        }
        lastBox = box;
      })
    });

    var objectiveVariable = new c.Variable();
    solver.addConstraint(new c.Equation(objectiveVariable, objectiveExpression));
    window.objectiveVariable = objectiveVariable;
    window.objectiveExpression = objectiveExpression;
    solver.optimize(objectiveVariable);
    solver.resolve();

  }
}
