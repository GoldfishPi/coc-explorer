import { fileColumnRegistrar } from '../fileColumnRegistrar';
import { FileNode, fileHighlights } from '../fileSource';

/**
 * indentLine
 *
 * │
 * └
 */
function printIndentLine(node: FileNode) {
  let row = '';
  if (node.parent?.isRoot) {
    return row;
  }
  if (node.nextSiblingNode === undefined) {
    row = '└ ';
  } else {
    row = '│ ';
  }
  let curNode = node.parent;
  while (curNode) {
    if (curNode.parent?.isRoot) {
      break;
    }
    if (curNode.nextSiblingNode === undefined) {
      row = '  ' + row;
    } else {
      row = '│ ' + row;
    }
    curNode = curNode.parent;
  }
  return row;
}

fileColumnRegistrar.registerColumn('child', 'indent', ({ source }) => ({
  draw() {
    const enabledNerdFont = source.config.enableNerdfont;
    return {
      drawNode(row, { node }) {
        const enableIndentLine = (() => {
          const indentLine = source.getColumnConfig<boolean | undefined>(
            'indent.indentLine',
          );
          if (enabledNerdFont && indentLine === undefined) {
            return true;
          } else {
            return indentLine;
          }
        })();

        if (enableIndentLine) {
          row.add(printIndentLine(node), { hl: fileHighlights.indentLine });
        } else {
          row.add(
            source
              .getColumnConfig<string>('indent.chars')
              .repeat((node.level ?? 0) - 1),
          );
        }
      },
    };
  },
}));
