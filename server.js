const express = require('express');
const WebSocket = require('ws');
const OSC = require('osc-js');
const http = require('http');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Serve static files
app.use(express.static('public'));

// Create OSC UDP client
const oscClient = new OSC({
  plugin: new OSC.DatagramPlugin({
    send: {
      port: 57120,      // SuperCollider's default OSC port
      host: 'localhost'
    }
  })
});

wss.on('connection', (ws) => {
  console.log('Client connected');
  
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      // Convert number strings to actual numbers
      const args = data.args.map(arg => typeof arg === 'string' && !isNaN(arg) ? Number(arg) : arg);
      const oscMessage = new OSC.Message(data.address, ...args); // Spread the args array
      oscClient.send(oscMessage);
      console.log('Sent OSC message:', oscMessage);
    } catch (error) {
      console.error('Error processing message:', error);
    }
  });
});

const PORT = 7700;
server.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
  oscClient.open();
});