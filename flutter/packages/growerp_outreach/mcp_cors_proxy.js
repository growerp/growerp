// Simple CORS proxy for Playwright MCP server
// Run: node mcp_cors_proxy.js
// Then connect Flutter web to http://localhost:9223/mcp

const http = require('http');

const TARGET_HOST = 'localhost';
const TARGET_PORT = 9222;
const PROXY_PORT = 9223;

const server = http.createServer((clientReq, clientRes) => {
  // Handle CORS preflight
  if (clientReq.method === 'OPTIONS') {
    clientRes.writeHead(200, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Accept, Mcp-Session-Id, Last-Event-Id',
      'Access-Control-Expose-Headers': 'Mcp-Session-Id',
      'Access-Control-Max-Age': '86400',
    });
    clientRes.end();
    return;
  }

  // Collect request body
  let body = [];
  clientReq.on('data', chunk => body.push(chunk));
  clientReq.on('end', () => {
    body = Buffer.concat(body);

    // Forward to Playwright MCP
    const options = {
      hostname: TARGET_HOST,
      port: TARGET_PORT,
      path: clientReq.url,
      method: clientReq.method,
      headers: { ...clientReq.headers, host: `${TARGET_HOST}:${TARGET_PORT}` },
    };

    const proxyReq = http.request(options, proxyRes => {
      // Add CORS headers to response
      const headers = {
        ...proxyRes.headers,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Expose-Headers': 'Mcp-Session-Id',
      };
      
      clientRes.writeHead(proxyRes.statusCode, headers);
      proxyRes.pipe(clientRes);
    });

    proxyReq.on('error', err => {
      console.error('Proxy error:', err.message);
      clientRes.writeHead(502, { 'Content-Type': 'text/plain' });
      clientRes.end('Bad Gateway');
    });

    proxyReq.write(body);
    proxyReq.end();
  });
});

server.listen(PROXY_PORT, () => {
  console.log(`CORS proxy listening on http://localhost:${PROXY_PORT}`);
  console.log(`Forwarding to http://${TARGET_HOST}:${TARGET_PORT}`);
});
