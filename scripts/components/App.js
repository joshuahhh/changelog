import React from 'react';
// import _ from 'underscore';

import SimpleSymbolDiagram from './SimpleSymbolDiagram';

import {SymbolDiagram} from '../SymbolDiagram';

import ElmDemoGroupInGroup from 'exports?Elm!../DemoGroupInGroup';
import ElmDemoInfinite from 'exports?Elm!../DemoInfinite';
const DemoGroupInGroup = ElmDemoGroupInGroup.DemoGroupInGroup.make(ElmDemoGroupInGroup);
const DemoInfinite = ElmDemoInfinite.DemoInfinite.make(ElmDemoInfinite);
window.DemoGroupInGroup = DemoGroupInGroup;
window.DemoInfinite = DemoInfinite;


var App = React.createClass({
  render() {
    // const symbolDiagram = group.clone('Top-Group').appendChild('Top-Group/group/node', group.clone('Bottom-Group'));
    const {symbolRenderingsInJson, environmentInJson, descriptionsInJson} = DemoGroupInGroup;
    window.symbolRenderingsInJson = symbolRenderingsInJson;
    window.environmentInJson = environmentInJson;
    const symbolDiagrams = symbolRenderingsInJson.map((symbolDiagramJson) =>
      new SymbolDiagram(symbolDiagramJson.blocks, symbolDiagramJson.rootId));

    return (
      <div style={{paddingTop: 20}}>
        <table>
          <tbody>
            {symbolDiagrams.map((symbolDiagram, i) =>
              <tr key={i}>
                <td style={{textAlign: 'right', verticalAlign: 'top', paddingRight: 30}}>
                  {descriptionsInJson[i]}
                </td>
                <td style={{paddingBottom: 35}}>
                  <SimpleSymbolDiagram symbolDiagram={symbolDiagram} environment={environmentInJson}/>
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    );
  },
});

export default App;
