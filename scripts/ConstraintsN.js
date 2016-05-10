import numeric from 'numeric';

export function gradient(f, x) {
    var n = x.length;
    var f0 = f(x);
    if(isNaN(f0)) throw new Error('gradient: f(x) is a NaN!');
    var max = Math.max;
    var i,x0 = numeric.clone(x),f1,f2, J = Array(n);
    var div = numeric.div, sub = numeric.sub,errest,roundoff,max = Math.max,eps = 1e-3,abs = Math.abs, min = Math.min;
    var t0,t1,t2,it=0,d1,d2,N;
    for(i=0;i<n;i++) {
        var h = max(1e-6*f0,1e-8);
        it = 0;  // JAH ADDITION
        while(1) {
            ++it;
            if(it>20) { throw new Error("Numerical gradient fails"); }
            x0[i] = x[i]+h;
            f1 = f(x0);
            x0[i] = x[i]-h;
            f2 = f(x0);
            x0[i] = x[i];
            if(isNaN(f1) || isNaN(f2)) { h/=16; continue; }
            J[i] = (f1-f2)/(2*h);
            t0 = x[i]-h;
            t1 = x[i];
            t2 = x[i]+h;
            d1 = (f1-f0)/h;
            d2 = (f0-f2)/h;
            N = max(abs(J[i]),abs(f0),abs(f1),abs(f2),abs(t0),abs(t1),abs(t2),1e-8);
            errest = min(max(abs(d1-J[i]),abs(d2-J[i]),abs(d1-d2))/N,h/N);
            if(errest>eps) { h/=16; }
            else break;
            }
    }
    return J;
}

export function sq(x) {
  return x * x;
}

export function pos(x) {
  return x < 0 ? (x * x) : 0;
}

export class Variable {
  constructor(props) {
    this.name = props.name;
    this.value = props.value;
  }
}

export class VariableSet {
  constructor(name, startingValues = {}) {
    this.name = name;
    this.startingValues = startingValues;
    this.variables = [];
  }

  constructVariable(variableName) {
    this[variableName] = new Variable({
      name: this.name + '.' + variableName,
      value: this.startingValues[variableName]
    });
    this.variables.push(this[variableName]);
  }

  constructVariables(variableNames) {
    variableNames.map(this.constructVariable.bind(this))
  }
}

export class Box extends VariableSet {
  constructor(name, startingValues = {}) {
    super(name, startingValues);
    this.constructVariables(
      ['left', 'right', 'top', 'bottom', 'centerX', 'centerY', 'width', 'height']
    );
  }

  getConstraintFunction() {
    return () => (
      sq(this.width.value - (this.right.value - this.left.value)) +
      sq(this.height.value - (this.bottom.value - this.top.value)) +
      sq(this.centerX.value - (this.right.value + this.left.value) / 2) +
      sq(this.centerY.value - (this.top.value + this.bottom.value) / 2) +
      pos(this.right.value - this.left.value) +
      pos(this.bottom.value - this.top.value)
    );
  }
}

export class NumericSolver {
  constructor() {
    this.variables = [];
    this.constraintFunctions = [];
    this.objectiveFunctions = [];
  }

  addVariable(variable) {
    this.variables.push(variable);
  }

  addConstraintFunction(constraintFunction) {
    this.constraintFunctions.push(constraintFunction);
  }

  addObjectiveFunction(objectiveFunction) {
    this.objectiveFunctions.push(objectiveFunction);
  }

  fullObjective(vec) {
    vec.forEach((value, index) => this.variables[index].value = value)

    var cum = 0;
    this.constraintFunctions.forEach((f) => cum += 10 * f())
    this.objectiveFunctions.forEach((f) => cum += f())
    return cum;
  }

  resolve() {
    var start = this.variables.map((variable) => variable.value || 1);
    var f = this.fullObjective.bind(this);
    var result = numeric.uncmin(f, start, undefined, (x) => gradient(f, x));
    result.solution.forEach((value, index) => this.variables[index].value = value);
  }
}
