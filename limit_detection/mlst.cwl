cwlVersion: v1.0
class: CommandLineTool
baseCommand: mlst
stdout: ${
        var splitAll = function (str) {
            return str.split('\\').pop().split('/').reverse()[0].replace(/___\w+$/g, '___mlst');
            };
        var dir = splitAll(inputs.contigs.location);
        return dir;
        }
inputs:
  contigs:
    type: File
    inputBinding:
      position: 1
outputs:
    mlstout:
        type: stdout
