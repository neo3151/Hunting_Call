import asyncio
import json
import base64
import sys
import os
import subprocess
import re
import websockets

WORKSPACE = "c:/Users/neo31/Hunting_Call"
DEST_DIR = f"{WORKSPACE}/play_store/screenshots_dark"
TEST_FILE = "integration_test/screenshot_test.dart"

async def capture_screenshot(ws_url, output_path):
    try:
        async with websockets.connect(ws_url) as ws:
            msg = {"jsonrpc": "2.0", "id": 1, "method": "_flutter.listViews"}
            await ws.send(json.dumps(msg))
            resp = json.loads(await ws.recv())
            
            views = resp.get("result", {}).get("views", [])
            if not views:
                print("No Flutter views found")
                return False
                
            msg = {
                "jsonrpc": "2.0",
                "id": 2,
                "method": "_flutter.screenshot",
            }
            await ws.send(json.dumps(msg))
            resp = json.loads(await ws.recv())
            
            if "result" in resp and "screenshot" in resp["result"]:
                img_data = base64.b64decode(resp["result"]["screenshot"])
                with open(output_path, "wb") as f:
                    f.write(img_data)
                print(f"✅ Saved screenshot: {output_path}")
                return True
    except Exception as e:
        print(f"Screenshot error: {e}")
    return False

async def main():
    if not os.path.exists(DEST_DIR):
        os.makedirs(DEST_DIR)
        
    print("[20%] Starting screenshot automation...")
    
    print("[40%] Running flutter test --machine...")
    
    cmd = " ".join([
        "flutter", "test",
        "-d", "windows", TEST_FILE,
        "--dart-define=FORCE_DARK_MODE=true", "--machine"
    ])
    
    process = subprocess.Popen(
        cmd,
        cwd=WORKSPACE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        shell=(os.name == 'nt')
    )
    
    ws_url = None
    
    try:
        while True:
            line = process.stdout.readline()
            if not line and process.poll() is not None:
                break
                
            line = line.strip()
            if line:
                try:
                    data = json.loads(line)
                    if isinstance(data, list):
                        data = data[0]
                    
                    event = data.get("event")
                    params = data.get("params", {})
                    
                    if event == "test.startedProcess" and "observatoryUri" in params:
                        raw_uri = params["observatoryUri"]
                        ws_url = raw_uri.replace("http://", "ws://").rstrip("/") + "/ws"
                        print(f"🔗 VM Service connected: {ws_url}")
                        print("[60%] App running. Waiting for snapshot triggers...")
                        
                    elif event == "print":
                        msg = params.get("message", "")
                        
                        trigger_match = re.search(r'📸 Taking screenshot \d+/15: ([\w_]+)\.\.\.', msg)
                        if trigger_match and ws_url:
                            name = trigger_match.group(1)
                            output_path = os.path.join(DEST_DIR, f"{name}.png")
                            print(msg)
                            await asyncio.sleep(0.5)
                            await capture_screenshot(ws_url, output_path)
                            
                        elif "ALL 15 SCREENSHOTS CAPTURED SUCCESSFULLY" in msg:
                            print("[100%] All screenshots finished successfully!")
                            process.terminate()
                            break
                            
                except json.JSONDecodeError:
                    pass
    finally:
        process.terminate()

if __name__ == "__main__":
    asyncio.run(main())
