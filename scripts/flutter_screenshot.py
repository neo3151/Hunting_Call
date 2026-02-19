#!/usr/bin/env python3
"""Capture a screenshot from a running Flutter app via its VM service."""
import asyncio
import json
import base64
import sys

async def capture_screenshot(vm_service_url: str, output_path: str):
    import websockets
    
    # Convert HTTP URL to WebSocket URL
    ws_url = vm_service_url.replace("http://", "ws://").rstrip("/") + "/ws"
    print(f"Connecting to: {ws_url}")
    
    async with websockets.connect(ws_url) as ws:
        # First get the list of views to find the flutter view ID
        msg = {"jsonrpc": "2.0", "id": 1, "method": "_flutter.listViews"}
        await ws.send(json.dumps(msg))
        resp = json.loads(await ws.recv())
        print(f"Views response: {json.dumps(resp, indent=2)[:500]}")
        
        # Get the view ID
        views = resp.get("result", {}).get("views", [])
        if not views:
            print("No Flutter views found!")
            return
        
        view_id = views[0]["id"]
        print(f"Using view: {view_id}")
        
        # Take screenshot
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
            print(f"Screenshot saved to {output_path} ({len(img_data)} bytes)")
        else:
            print(f"Error: {json.dumps(resp, indent=2)[:500]}")

if __name__ == "__main__":
    vm_url = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:44399/QIjQ3-mYEfk=/"
    output = sys.argv[2] if len(sys.argv) > 2 else "/tmp/flutter_screenshot.png"
    asyncio.run(capture_screenshot(vm_url, output))
