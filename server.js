const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3000;
const PUBLIC_DIR = path.join(__dirname, 'public');

// In-memory notification analytics store
const notificationMetrics = {
  total_delivered: 0,
  total_opened: 0,
  notifications: {}
};

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

const server = http.createServer((req, res) => {
  // CORS Headers for API requests
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.url === '/api/health') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({
      status: 'online',
      app: 'Smart X Ethiopian Educational Platform',
      timestamp: new Date().toISOString()
    }));
    return;
  }

  // Notification Analytics API - Track Delivered vs Opened
  if (req.url === '/api/notifications/track' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    req.on('end', () => {
      try {
        const payload = JSON.parse(body || '{}');
        const notifId = payload.notification_id || 'general';
        const eventType = payload.event || 'delivered';
        const actionId = payload.action_id || null;
        const targetType = payload.target_type || 'general';
        const timestamp = payload.timestamp || new Date().toISOString();

        if (!notificationMetrics.notifications[notifId]) {
          notificationMetrics.notifications[notifId] = {
            notification_id: notifId,
            target_type: targetType,
            delivered_count: 0,
            opened_count: 0,
            last_action_id: null,
            last_updated: timestamp
          };
        }

        const notifObj = notificationMetrics.notifications[notifId];

        if (eventType === 'delivered') {
          notificationMetrics.total_delivered += 1;
          notifObj.delivered_count += 1;
        } else if (eventType === 'opened') {
          notificationMetrics.total_opened += 1;
          notifObj.opened_count += 1;
          if (actionId) notifObj.last_action_id = actionId;
        }

        notifObj.last_updated = timestamp;

        console.log(`[API /api/notifications/track] Tracked event='${eventType}' for id='${notifId}' (delivered: ${notifObj.delivered_count}, opened: ${notifObj.opened_count})`);

        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({
          success: true,
          message: `Event '${eventType}' tracked successfully`,
          data: {
            notification_id: notifId,
            delivered_count: notifObj.delivered_count,
            opened_count: notifObj.opened_count,
            total_delivered: notificationMetrics.total_delivered,
            total_opened: notificationMetrics.total_opened
          }
        }));
      } catch (err) {
        console.error('Error processing /api/notifications/track:', err);
        res.writeHead(400, { 'Content-Type': 'application/json; charset=utf-8' });
        res.end(JSON.stringify({ success: false, error: 'Invalid JSON payload' }));
      }
    });
    return;
  }

  // Notification Analytics API - Fetch Stats for Admin Dashboard
  if (req.url === '/api/notifications/stats' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify({
      success: true,
      data: notificationMetrics
    }));
    return;
  }

  let filePath = path.join(PUBLIC_DIR, req.url === '/' ? 'index.html' : req.url);

  // Prevent directory traversal
  if (!filePath.startsWith(PUBLIC_DIR)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      filePath = path.join(PUBLIC_DIR, 'index.html');
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    fs.readFile(filePath, (readErr, data) => {
      if (readErr) {
        res.writeHead(500);
        res.end('Server Error');
        return;
      }
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(data);
    });
  });
});

server.listen(PORT, () => {
  console.log(`Smart X Academy server listening on port ${PORT}`);
});

