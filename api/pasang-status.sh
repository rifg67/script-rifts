#!/bin/bash
# Pasang endpoint /status (cek kesehatan server) ke API api-xwan.
# Aman dijalankan berulang: kalau sudah terpasang tidak ada yang diubah.
# Dipakai oleh bot seller (tombol Cek Status Server) lewat http://domain:5888/status?auth=KEY

J=${J:-/usr/bin/api-xwan/api.js}
[ -f "$J" ] || { echo "[status] api.js tidak ditemukan di $J, dilewati"; exit 0; }

SNIP=$(mktemp)
cat > "$SNIP" <<'EOF'
// === STATUS SERVER ===
app.get("/status", (req, res) => {
  const { auth } = req.query;
  if (!process.env.AUTH_KEY || auth !== process.env.AUTH_KEY)
    return res.status(403).json({ status: "error", message: "Forbidden" });
  const { execFile } = require("child_process");
  const os = require("os");
  const names = ["ssh", "xray", "nginx", "haproxy", "ws", "dropbear"];
  const services = {};
  let left = names.length;
  names.forEach((n) => {
    execFile("systemctl", ["is-active", n], { timeout: 5000 }, (err, out) => {
      services[n] = (out || "").trim() || "unknown";
      if (--left === 0) {
        const core = ["xray", "ssh"].every((k) => services[k] === "active");
        res.json({
          status: "success",
          server: core ? "online" : "degraded",
          uptime_hours: Math.floor(os.uptime() / 3600),
          load: os.loadavg()[0].toFixed(2),
          ram_used_pct: Math.round((1 - os.freemem() / os.totalmem()) * 100),
          services,
        });
      }
    });
  });
});
EOF

changed=0
if grep -q 'app.get("/status"' "$J"; then
  # /status versi lama (tanpa ws): tambahkan ws ke daftar service
  if ! grep -q '"ws"' "$J"; then
    cp "$J" "$J.bak"
    sed -i 's/\["ssh", "xray", "nginx", "haproxy", "dropbear"\]/["ssh", "xray", "nginx", "haproxy", "ws", "dropbear"]/' "$J" && changed=1
  fi
else
  LN=$(grep -n 'app.use(express.json());' "$J" | head -1 | cut -d: -f1)
  if [ -z "$LN" ]; then
    echo "[status] titik pasang tidak ketemu di api.js, dilewati (tidak ada yang diubah)"
    rm -f "$SNIP"; exit 0
  fi
  cp "$J" "$J.bak"
  sed -i "${LN}r $SNIP" "$J" && changed=1
fi
rm -f "$SNIP"

if [ "$changed" = 1 ]; then
  if node --check "$J" 2>/dev/null; then
    echo "[status] endpoint /status terpasang"
    command -v systemctl >/dev/null 2>&1 && systemctl restart apisellvpn 2>/dev/null
  else
    cp "$J.bak" "$J"
    echo "[status] syntax error setelah patch, api.js dikembalikan dari backup"
  fi
else
  echo "[status] sudah terpasang, tidak ada perubahan"
fi
exit 0
