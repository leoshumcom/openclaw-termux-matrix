// OpenClaw Matrix APK Download Portal
// Serves APK download links from Cloudflare R2
// Deploy to: https://dash.cloudflare.com -> Workers & Pages
// Account: leoshum.com@gmail.com (1号账户)
// Setup: wrangler.toml needs R2 binding 'openclaw_apk_bucket'

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // List available APKs
    if (path === '/' || path === '/list') {
      const objects = await env.openclaw_apk_bucket.list();
      let html = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>OpenClaw Matrix APK Downloads</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background: #0a0a0a;
      color: #00ff41;
      font-family: 'Courier New', monospace;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .container {
      max-width: 700px;
      width: 100%;
      border: 1px solid #00ff41;
      padding: 30px;
    }
    h1 {
      font-size: 18px;
      letter-spacing: 4px;
      text-align: center;
      margin-bottom: 20px;
      text-transform: uppercase;
    }
    .subtitle {
      font-size: 11px;
      color: #3b7a3b;
      text-align: center;
      margin-bottom: 30px;
    }
    .file-list {
      list-style: none;
    }
    .file-item {
      border: 1px solid #1a3a1a;
      padding: 12px 16px;
      margin: 6px 0;
      display: flex;
      justify-content: space-between;
      align-items: center;
      transition: border-color 0.2s;
    }
    .file-item:hover {
      border-color: #00ff41;
    }
    .file-name {
      font-size: 13px;
      color: #8bc34a;
    }
    .file-size {
      font-size: 11px;
      color: #3b7a3b;
    }
    .download-btn {
      background: none;
      border: 1px solid #00ff41;
      color: #00ff41;
      padding: 6px 16px;
      cursor: pointer;
      font-family: 'Courier New', monospace;
      font-size: 11px;
      letter-spacing: 1px;
      text-decoration: none;
      transition: background 0.2s;
    }
    .download-btn:hover {
      background: #00ff4120;
    }
    .footer {
      margin-top: 30px;
      font-size: 10px;
      color: #1a5a1a;
      text-align: center;
    }
    .empty {
      text-align: center;
      color: #3b7a3b;
      padding: 40px 0;
    }
    .badge {
      display: inline-block;
      border: 1px solid #3b7a3b;
      padding: 3px 8px;
      font-size: 10px;
      color: #3b7a3b;
      margin-left: 8px;
      letter-spacing: 1px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>// OPENCLAW_MATRIX</h1>
    <div class="subtitle">[ APK DOWNLOAD PORTAL ] <span class="badge">v1.0.0</span></div>
    <p style="font-size:11px;color:#3b7a3b;text-align:center;margin-bottom:20px;">
      Based on <a href="https://github.com/mithun50/openclaw-termux" style="color:#8bc34a;">openclaw-termux</a> (MIT) — Matrix Edition
    </p>`;

      if (objects.objects.length === 0) {
        html += `<div class="empty">> no_apk_found<br/>build_pending...</div>`;
      } else {
        html += `<ul class="file-list">`;
        for (const obj of objects.objects) {
          const size = obj.size > 1024 * 1024
            ? (obj.size / 1024 / 1024).toFixed(1) + ' MB'
            : (obj.size / 1024).toFixed(1) + ' KB';
          html += `
            <li class="file-item">
              <div>
                <div class="file-name">${obj.key}</div>
                <div class="file-size">${size}</div>
              </div>
              <a class="download-btn" href="/download/${obj.key}" download>> GET</a>
            </li>`;
        }
        html += `</ul>`;
      }

      html += `
    <div class="footer">
      <p>> last_build: ${new Date().toISOString()}</p>
      <p>&gt; deploy via: github actions → cloudflare r2</p>
    </div>
  </div>
</body>
</html>`;
      return new Response(html, {
        headers: { 'content-type': 'text/html; charset=utf-8' },
      });
    }

    // Download an APK
    if (path.startsWith('/download/')) {
      const key = path.slice('/download/'.length);
      const object = await env.openclaw_apk_bucket.get(key);
      if (!object) {
        return new Response('Not Found', { status: 404 });
      }
      return new Response(object.body, {
        headers: {
          'content-type': 'application/vnd.android.package-archive',
          'content-disposition': `attachment; filename="${key}"`,
          'cache-control': 'public, max-age=3600',
        },
      });
    }

    return new Response('Not Found', { status: 404 });
  },
};
