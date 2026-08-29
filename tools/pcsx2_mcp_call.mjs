import { Client } from '../external/PCSX2-MCP/PCSX2-MCP-v1.0.0-win64/PCSX2-MCP-v1.0.0-win64/pcsx2-mcp-server/node_modules/@modelcontextprotocol/sdk/dist/esm/client/index.js';
import { StdioClientTransport } from '../external/PCSX2-MCP/PCSX2-MCP-v1.0.0-win64/PCSX2-MCP-v1.0.0-win64/pcsx2-mcp-server/node_modules/@modelcontextprotocol/sdk/dist/esm/client/stdio.js';

const serverPath = new URL(
  '../external/PCSX2-MCP/PCSX2-MCP-v1.0.0-win64/PCSX2-MCP-v1.0.0-win64/pcsx2-mcp-server/dist/index.js',
  import.meta.url,
);
const toolName = process.argv[2] ?? 'pcsx2_status';
const toolArgs = process.argv[3] ? JSON.parse(process.argv[3]) : {};

const transport = new StdioClientTransport({
  command: process.execPath,
  args: [decodeURIComponent(serverPath.pathname).replace(/^\/(?:([A-Za-z]:))/, '$1')],
  stderr: 'pipe',
});
const client = new Client({ name: 'mc3-pcsx2-capture', version: '1.0.0' });

try {
  await client.connect(transport);
  const connection = await client.callTool({
    name: 'pcsx2_connect',
    arguments: { debug_port: 21512, pine_port: 28011, mode: 'auto' },
  });
  const result = toolName === 'pcsx2_connect'
    ? connection
    : await client.callTool({ name: toolName, arguments: toolArgs });
  process.stdout.write(`${JSON.stringify({ connection, result }, null, 2)}\n`);
} finally {
  await client.close();
}
