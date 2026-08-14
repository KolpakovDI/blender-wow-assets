#!/usr/bin/env node
/**
 * Upload hex batches to Roblox Studio via MCP stdio (mcp.bat).
 * Usage: node scripts/studio_hex_upload.mjs [startBatch] [endBatch]
 */
import { spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const HEX_DIR = path.join(__dirname, '..', 'docs/realm-of-spirits/studio/_city_hex3');
const MCP_BAT = path.join(process.env.LOCALAPPDATA || '', 'Roblox', 'mcp.bat');

const startBatch = Number(process.argv[2] ?? 0);
const endBatch = Number(process.argv[3] ?? 6);

function readBatchCode(i) {
  return fs.readFileSync(path.join(HEX_DIR, `code_only_${i}.luau`), 'utf8');
}

function mcpRequest(client, method, params, id) {
  return new Promise((resolve, reject) => {
    const req = JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n';
    let buf = '';
    const onData = (chunk) => {
      buf += chunk.toString();
      const lines = buf.split('\n');
      buf = lines.pop() ?? '';
      for (const line of lines) {
        if (!line.trim()) continue;
        try {
          const msg = JSON.parse(line);
          if (msg.id === id) {
            client.stdout.off('data', onData);
            if (msg.error) reject(new Error(JSON.stringify(msg.error)));
            else resolve(msg.result);
          }
        } catch (_) {}
      }
    };
    client.stdout.on('data', onData);
    client.stdin.write(req);
  });
}

async function main() {
  if (!fs.existsSync(MCP_BAT)) {
    console.error('MCP bat not found:', MCP_BAT);
    process.exit(1);
  }

  const child = spawn('cmd.exe', ['/c', MCP_BAT], { stdio: ['pipe', 'pipe', 'pipe'] });
  child.stderr.on('data', (d) => process.stderr.write(d));

  // initialize
  await mcpRequest(child, 'initialize', {
    protocolVersion: '2024-11-05',
    capabilities: {},
    clientInfo: { name: 'hex-upload', version: '1.0' },
  }, 1);
  child.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');

  const lengths = [];
  for (let i = startBatch; i <= endBatch; i++) {
    const code = readBatchCode(i);
    const result = await mcpRequest(child, 'tools/call', {
      name: 'execute_luau',
      arguments: { code, datamodel_type: 'Edit' },
    }, 10 + i);
    const text = result?.content?.[0]?.text ?? JSON.stringify(result);
    lengths.push({ batch: i, result: text, codeLen: code.length });
    console.log(`batch ${i}: ${text} (code ${code.length} chars)`);
  }

  child.kill();
  console.log(JSON.stringify({ lengths }, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
