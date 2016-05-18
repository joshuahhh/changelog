import React from 'react';

const nl2br = (text) => text.split('\n').map((line) =>
  <span>
    {line}
    <br/>
  </span>
);


const Story = ({story, characterRenderer, showStart}) =>
  <table>
    <tbody>
      {showStart &&
        <tr>
          <td style={{textAlign: 'right', verticalAlign: 'top', paddingRight: 30}}>
            start
          </td>
          <td style={{textAlign: 'left', verticalAlign: 'top', paddingRight: 30, paddingBottom: 35}}>
            {characterRenderer(story.start)}
          </td>
        </tr>
      }
      {story.steps.map((step, i) =>
        step.narration &&
          <tr key={i}>
            <td style={{textAlign: 'right', verticalAlign: 'top', paddingRight: 30}}>
              {nl2br(step.narration)}
            </td>
            <td style={{textAlign: 'left', verticalAlign: 'top', paddingRight: 30, paddingBottom: 35}}>
              {characterRenderer(step.after)}
            </td>
            <td style={{paddingBottom: 35}}>
              <Story story={step.explanation} characterRenderer={characterRenderer} />
            </td>
          </tr>
      )}
    </tbody>
  </table>;

export default Story;
