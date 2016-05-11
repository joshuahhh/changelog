/* global c */

import _ from 'underscore';

export class VariableSet {
  constructor(name, startingValues = {}) {
    this.name = name;
    this.startingValues = startingValues;
  }

  constructVariable(variableName) {
    this[variableName] = new c.Variable({
      name: this.name + '.' + variableName,
      value: this.startingValues[variableName]
    });
  }

  constructVariables(variableNames) {
    variableNames.map(this.constructVariable.bind(this));
  }

  constrain(solver) {
    this.getConstraints().forEach((constraint) => solver.addConstraint(constraint));
  }
}

export class Box extends VariableSet {
  constructor(name, startingValues = {}) {
    super(name, startingValues);
    this.constructVariables(
      ['left', 'right', 'top', 'bottom', 'centerX', 'centerY', 'width', 'height']
    );
  }

  getConstraints() {
    return [
      new c.Equation(this.width, c.minus(this.right, this.left)),
      new c.Equation(this.height, c.minus(this.bottom, this.top)),
      new c.Equation(c.minus(this.right, this.centerX), c.minus(this.centerX, this.left)),
      new c.Equation(c.minus(this.top, this.centerY), c.minus(this.centerY, this.bottom)),
      new c.Inequality(this.left, c.LEQ, this.right),
      new c.Inequality(this.top, c.LEQ, this.bottom),
    ];
  }

  getBoundValues() {
    return {
      left: this.left.value,
      right: this.right.value,
      top: this.top.value,
      bottom: this.bottom.value
    };
  }

  constrainToBeInside(otherBox, padding, solver) {
    solver.addConstraint(new c.Inequality(this.top, c.GEQ, c.plus(otherBox.top, padding)));
    solver.addConstraint(new c.Inequality(this.bottom, c.LEQ, c.plus(otherBox.bottom, -padding)));
    solver.addConstraint(new c.Inequality(this.left, c.GEQ, c.plus(otherBox.left, padding)));
    solver.addConstraint(new c.Inequality(this.right, c.LEQ, c.plus(otherBox.right, -padding)));
  }
}

export function addAbsoluteValueToObjective(objective, expr1, expr2, solver, weight=1) {
  // console.log('addAbsoluteValueToObjective', objective, expr1, expr2, solver)
  const positivePart = new c.Variable();
  const negativePart = new c.Variable();
  solver.addConstraint(new c.Inequality(positivePart, c.GEQ, 0));
  solver.addConstraint(new c.Inequality(negativePart, c.GEQ, 0));
  solver.addConstraint(new c.Equation(expr1, c.plus(expr2, c.minus(positivePart, negativePart))));

  var toReturn = c.plus(objective, c.times(c.plus(positivePart, negativePart), weight));
  // var toReturn = objective;
  return toReturn;
}

export function addPseudoQuadraticToObjective(objective, expr1, expr2, solver, halfRange, step, weight=1) {
  _.range(-halfRange, halfRange + 0.001, step).forEach((x) =>
    objective = addAbsoluteValueToObjective(objective, expr1, c.plus(expr2, x), solver, weight)
  );
  return objective;
}
