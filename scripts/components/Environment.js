import React from 'react';
import _ from 'underscore';

var Environment = React.createClass({
  render() {
    const {environment} = this.props;
    const {symbols} = environment;

    return (
      <div style={{display: 'flex'}}>
        {_.map(symbols, (symbol, symbolName) =>
          <div style={{background: '#E0E0E0', marginRight: 20, padding: 25, borderRadius: 10, width: 400}}>
            <h3 style={{marginTop: 0}}>{symbolName} <small>Symbol</small></h3>
            <h4>Changes</h4>
            <ol start="0" style={{paddingLeft: 20}}>
              {symbol.changes.map((change) =>
                <li>{change.description}</li>
              )}
            </ol>
          </div>
        )}
      </div>
    );
  },
});

export default Environment;
