#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
output="$repo_root/docs/skill-graph-options/compact-skill-network.png"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/moos_skill_graph.XXXXXX")"
server_pid=""

cleanup() {
  if [ -n "$server_pid" ]; then
    kill "$server_pid" >/dev/null 2>&1 || true
    wait "$server_pid" 2>/dev/null || true
  fi
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

python_bin="${PYTHON_BIN:-python3}"
node_bin="${NODE_BIN:-node}"
playwright_package="${PLAYWRIGHT_PACKAGE:-playwright}"
chrome_executable="${CHROME_EXECUTABLE:-}"

# README export dimensions. The browser renders the full README frame, then
# Playwright captures the intended grid-aligned rectangle from that frame.
export_css_width=1312
export_css_height=700
device_scale=2

grid_css_px=38
half_grid_css_px=$((grid_css_px / 2))

# Final README framing:
# - one grid square from each side
# - half a grid square from the top
# - one grid square from the bottom
clip_x_css="$grid_css_px"
clip_y_css="$half_grid_css_px"
clip_width_css=$((export_css_width - grid_css_px * 2))
clip_height_css=$((export_css_height - half_grid_css_px - grid_css_px))

port="$("$python_bin" - <<'PY'
import socket
with socket.socket() as s:
    s.bind(("127.0.0.1", 0))
    print(s.getsockname()[1])
PY
)"

(
  cd "$repo_root"
  "$python_bin" -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1
) &
server_pid="$!"

full_export="$tmp_dir/full.png"

EXPORT_CSS_WIDTH="$export_css_width" \
EXPORT_CSS_HEIGHT="$export_css_height" \
CLIP_X_CSS="$clip_x_css" \
CLIP_Y_CSS="$clip_y_css" \
CLIP_WIDTH_CSS="$clip_width_css" \
CLIP_HEIGHT_CSS="$clip_height_css" \
DEVICE_SCALE="$device_scale" \
EXPORT_URL="http://127.0.0.1:$port/docs/skill-graph-options/analysis-network.html?variant=compact&export=readme" \
FULL_EXPORT="$full_export" \
PLAYWRIGHT_PACKAGE="$playwright_package" \
CHROME_EXECUTABLE="$chrome_executable" \
"$node_bin" <<'NODE'
const { chromium } = require(process.env.PLAYWRIGHT_PACKAGE);

(async () => {
  const launchOptions = { headless: true };
  if (process.env.CHROME_EXECUTABLE) {
    launchOptions.executablePath = process.env.CHROME_EXECUTABLE;
  }

  const browser = await chromium.launch(launchOptions);
  const page = await browser.newPage({
    viewport: {
      width: Number(process.env.EXPORT_CSS_WIDTH),
      height: Number(process.env.EXPORT_CSS_HEIGHT),
    },
    deviceScaleFactor: Number(process.env.DEVICE_SCALE),
  });

  await page.goto(process.env.EXPORT_URL, {
    waitUntil: "domcontentloaded",
    timeout: 30000,
  });
  await page.waitForSelector("#graph canvas", { timeout: 30000 });
  await page.waitForTimeout(1000);
  const frame = await page.locator(".graph-frame").boundingBox();
  await page.screenshot({
    path: process.env.FULL_EXPORT,
    clip: {
      x: frame.x + Number(process.env.CLIP_X_CSS),
      y: frame.y + Number(process.env.CLIP_Y_CSS),
      width: Number(process.env.CLIP_WIDTH_CSS),
      height: Number(process.env.CLIP_HEIGHT_CSS),
    },
  });
  await browser.close();
})();
NODE

mv "$full_export" "$output"

printf 'Wrote %s\n' "$output"
