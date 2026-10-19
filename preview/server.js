const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const root = __dirname;
const file = path.join(root, 'index.html');
const server = http.createServer((req, res) => {
  if (req.url === '/' || req.url === '/index.html') {
    res.writeHead(200, { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store' });
    fs.createReadStream(file).pipe(res);
  } else {
    res.writeHead(404, { 'content-type': 'text/plain; charset=utf-8' });
    res.end('Not found');
  }
});
server.listen(5173, '127.0.0.1', () => process.stdout.write('Preview ready at http://127.0.0.1:5173\n'));
