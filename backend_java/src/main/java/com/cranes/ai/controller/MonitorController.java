package com.cranes.ai.controller;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MonitorController {

    private static final String MONITOR_HTML = """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Cranes Varsity Java AI Engine — Live Activity Monitor</title>
                <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&family=JetBrains+Mono:wght@400;700&display=swap" rel="stylesheet">
                <style>
                    :root {
                        --bg: #090D16;
                        --card-bg: rgba(18, 26, 43, 0.75);
                        --border: rgba(255, 255, 255, 0.1);
                        --primary: #6366F1;
                        --accent: #06B6D4;
                        --success: #10B981;
                        --warning: #F59E0B;
                        --danger: #EF4444;
                        --text-main: #F8FAFC;
                        --text-muted: #94A3B8;
                    }
                    * { box-sizing: border-box; margin: 0; padding: 0; }
                    body {
                        font-family: 'Plus Jakarta Sans', sans-serif;
                        background: var(--bg);
                        color: var(--text-main);
                        min-height: 100vh;
                        padding: 24px;
                        background-image: 
                            radial-gradient(circle at 15% 15%, rgba(99, 102, 241, 0.12) 0%, transparent 40%),
                            radial-gradient(circle at 85% 85%, rgba(6, 182, 212, 0.10) 0%, transparent 40%);
                    }
                    .container { max-width: 1280px; margin: 0 auto; }
                    header {
                        display: flex; align-items: center; justify-content: space-between;
                        padding-bottom: 24px; border-bottom: 1px solid var(--border); margin-bottom: 24px;
                    }
                    .brand { display: flex; align-items: center; gap: 14px; }
                    .brand-logo {
                        width: 44px; height: 44px;
                        background: linear-gradient(135deg, var(--primary), var(--accent));
                        border-radius: 12px; display: flex; align-items: center; justify-content: center;
                        font-size: 22px; font-weight: 800; color: #fff;
                        box-shadow: 0 0 20px rgba(99, 102, 241, 0.4);
                    }
                    .brand-title h1 { font-size: 20px; font-weight: 800; letter-spacing: -0.5px; }
                    .brand-title p { font-size: 12px; color: var(--text-muted); font-weight: 600; }
                    .status-badge {
                        display: inline-flex; align-items: center; gap: 8px;
                        background: rgba(16, 185, 129, 0.12); border: 1px solid rgba(16, 185, 129, 0.3);
                        color: var(--success); padding: 8px 16px; border-radius: 100px;
                        font-size: 13px; font-weight: 700;
                    }
                    .status-dot {
                        width: 9px; height: 9px; background: var(--success); border-radius: 50%;
                        box-shadow: 0 0 10px var(--success); animation: pulse 1.8s infinite;
                    }
                    @keyframes pulse { 0%, 100% { opacity: 1; transform: scale(1); } 50% { opacity: 0.5; transform: scale(0.85); } }
                    .stats-grid {
                        display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
                        gap: 16px; margin-bottom: 28px;
                    }
                    .stat-card {
                        background: var(--card-bg); border: 1px solid var(--border);
                        backdrop-filter: blur(16px); padding: 20px; border-radius: 16px;
                    }
                    .stat-label { font-size: 12px; color: var(--text-muted); font-weight: 700; text-transform: uppercase; letter-spacing: 0.8px; }
                    .stat-val { font-size: 28px; font-weight: 800; margin-top: 6px; color: #fff; }
                    .stream-card {
                        background: var(--card-bg); border: 1px solid var(--border);
                        backdrop-filter: blur(16px); border-radius: 20px; padding: 20px; overflow: hidden;
                    }
                    .log-item {
                        padding: 16px; border-radius: 14px;
                        background: rgba(255, 255, 255, 0.02); border: 1px solid rgba(255, 255, 255, 0.04);
                        margin-bottom: 12px; transition: 0.2s;
                    }
                    .log-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; }
                    .tag {
                        padding: 3px 8px; border-radius: 6px; font-family: 'JetBrains Mono', monospace;
                        font-size: 11px; font-weight: 700; text-transform: uppercase;
                    }
                    .tag-SUCCESS { background: rgba(16, 185, 129, 0.2); color: var(--success); }
                    .tag-INFO { background: rgba(99, 102, 241, 0.2); color: #818CF8; }
                    .tag-ERROR { background: rgba(239, 68, 68, 0.25); color: var(--danger); }
                    .log-time { font-family: 'JetBrains Mono', monospace; font-size: 12px; color: var(--text-muted); }
                    .candidate-tag { font-size: 12px; font-weight: 700; color: var(--accent); }
                    .log-body { font-size: 13.5px; line-height: 1.5; color: #E2E8F0; }
                </style>
            </head>
            <body>
                <div class="container">
                    <header>
                        <div class="brand">
                            <div class="brand-logo">☕</div>
                            <div class="brand-title">
                                <h1>Cranes Varsity — Spring Boot Java AI Engine Monitor</h1>
                                <p>Live Mobile App & Java Backend Activity Stream (Port 8000)</p>
                            </div>
                        </div>
                        <div class="status-badge">
                            <span class="status-dot"></span>
                            <span>Java Spring Boot Online</span>
                        </div>
                    </header>

                    <div class="stats-grid">
                        <div class="stat-card">
                            <div class="stat-label">Total Logged Events</div>
                            <div class="stat-val" id="stat-total">0</div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-label">Active Sessions</div>
                            <div class="stat-val" id="stat-sessions" style="color: var(--accent);">0</div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-label">Java Framework</div>
                            <div class="stat-val" style="font-size: 18px; color: var(--primary);">Spring Boot 3.2</div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-label">Health Status</div>
                            <div class="stat-val" style="color: var(--success);">100% OK</div>
                        </div>
                    </div>

                    <div class="stream-card">
                        <div id="log-container">
                            <p style="text-align: center; color: var(--text-muted); padding: 40px;">Polling Java backend activity logs...</p>
                        </div>
                    </div>
                </div>

                <script>
                    async function fetchLogs() {
                        try {
                            const res = await fetch('/api/v1/monitor/logs');
                            if (res.ok) {
                                const data = await res.json();
                                document.getElementById('stat-total').innerText = data.total || 0;
                                document.getElementById('stat-sessions').innerText = data.active_sessions || 0;
                                renderLogs(data.logs || []);
                            }
                        } catch (e) { console.error("Monitor fetch error:", e); }
                    }

                    function renderLogs(logs) {
                        const container = document.getElementById('log-container');
                        if (logs.length === 0) {
                            container.innerHTML = '<p style="text-align: center; color: var(--text-muted); padding: 40px;">No events logged yet. Perform an action in the mobile app!</p>';
                            return;
                        }
                        let html = '';
                        logs.forEach(l => {
                            html += `
                                <div class="log-item">
                                    <div class="log-header">
                                        <div>
                                            <span class="tag tag-${l.level}">${l.eventType}</span>
                                            <span class="candidate-tag" style="margin-left: 8px;">👤 ${l.candidateName}</span>
                                        </div>
                                        <span class="log-time">⏱️ ${l.timestamp}</span>
                                    </div>
                                    <div class="log-body">${l.details}</div>
                                </div>
                            `;
                        });
                        container.innerHTML = html;
                    }

                    setInterval(fetchLogs, 2000);
                    fetchLogs();
                </script>
            </body>
            </html>
            """;

    @GetMapping(value = {"/", "/monitor"}, produces = MediaType.TEXT_HTML_VALUE)
    public String getMonitorDashboard() {
        return MONITOR_HTML;
    }
}
