#!/usr/bin/env node

/**
 * MCP HTTP Bridge Server
 * 
 * Exposes browsermcp MCP tools as HTTP REST endpoints
 * for Flutter/Dart applications to consume.
 * 
 * Usage: node mcp_http_bridge.js
 */

const express = require('express');
const { Client } = require('@modelcontextprotocol/sdk/client/index.js');
const { StdioClientTransport } = require('@modelcontextprotocol/sdk/client/stdio.js');

const app = express();
const PORT = process.env.MCP_BRIDGE_PORT || 3000;

app.use(express.json());

// CORS for local development
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// MCP Client instance
let mcpClient = null;

// Initialize MCP client
async function initializeMCP() {
  try {
    const transport = new StdioClientTransport({
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-browsermcp'],
    });

    mcpClient = new Client({
      name: 'mcp-http-bridge',
      version: '1.0.0',
    }, {
      capabilities: {},
    });

    await mcpClient.connect(transport);
    console.log('✓ Connected to browsermcp MCP server');

    // List available tools
    const tools = await mcpClient.listTools();
    console.log(`✓ Available tools: ${tools.tools.map(t => t.name).join(', ')}`);
  } catch (error) {
    console.error('Failed to initialize MCP client:', error);
    throw error;
  }
}

// Generic MCP tool caller
async function callMCPTool(toolName, params) {
  if (!mcpClient) {
    throw new Error('MCP client not initialized');
  }

  try {
    const result = await mcpClient.callTool({
      name: toolName,
      arguments: params,
    });

    return result;
  } catch (error) {
    console.error(`Error calling tool ${toolName}:`, error);
    throw error;
  }
}

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    mcpConnected: mcpClient !== null,
  });
});

// Browser navigate
app.post('/mcp/browser_navigate', async (req, res) => {
  try {
    const { url } = req.body;
    await callMCPTool('mcp0_browser_navigate', { url });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Browser snapshot
app.post('/mcp/browser_snapshot', async (req, res) => {
  try {
    const result = await callMCPTool('mcp0_browser_snapshot', {});
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Browser click
app.post('/mcp/browser_click', async (req, res) => {
  try {
    const { element, ref } = req.body;
    await callMCPTool('mcp0_browser_click', { element, ref });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Browser type
app.post('/mcp/browser_type', async (req, res) => {
  try {
    const { element, ref, text, submit } = req.body;
    await callMCPTool('mcp0_browser_type', { element, ref, text, submit });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Browser wait
app.post('/mcp/browser_wait', async (req, res) => {
  try {
    const { time } = req.body;
    await callMCPTool('mcp0_browser_wait', { time });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Browser screenshot
app.post('/mcp/browser_screenshot', async (req, res) => {
  try {
    const result = await callMCPTool('mcp0_browser_screenshot', {});
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Browser go back
app.post('/mcp/browser_go_back', async (req, res) => {
  try {
    await callMCPTool('mcp0_browser_go_back', {});
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Browser go forward
app.post('/mcp/browser_go_forward', async (req, res) => {
  try {
    await callMCPTool('mcp0_browser_go_forward', {});
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Browser hover
app.post('/mcp/browser_hover', async (req, res) => {
  try {
    const { element, ref } = req.body;
    await callMCPTool('mcp0_browser_hover', { element, ref });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Browser press key
app.post('/mcp/browser_press_key', async (req, res) => {
  try {
    const { key } = req.body;
    await callMCPTool('mcp0_browser_press_key', { key });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Browser select option
app.post('/mcp/browser_select_option', async (req, res) => {
  try {
    const { element, ref, values } = req.body;
    await callMCPTool('mcp0_browser_select_option', { element, ref, values });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Browser get console logs
app.post('/mcp/browser_get_console_logs', async (req, res) => {
  try {
    const result = await callMCPTool('mcp0_browser_get_console_logs', {});
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Start server
async function start() {
  try {
    await initializeMCP();

    app.listen(PORT, () => {
      console.log(`\n🚀 MCP HTTP Bridge running on http://localhost:${PORT}`);
      console.log(`   Health check: http://localhost:${PORT}/health`);
      console.log(`   MCP endpoints: http://localhost:${PORT}/mcp/*\n`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\nShutting down...');
  if (mcpClient) {
    await mcpClient.close();
  }
  process.exit(0);
});

start();
