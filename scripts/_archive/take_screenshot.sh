#!/bin/bash
# Captures a screenshot from a running Flutter app via its VM service
# Usage: ./take_screenshot.sh <vm_service_ws_url> <output_file.png>

VM_URL="$1"
OUTPUT="$2"

if [ -z "$VM_URL" ] || [ -z "$OUTPUT" ]; then
  echo "Usage: $0 <vm_service_ws_url> <output_file.png>"
  exit 1
fi

# Convert http URL to websocket URL and call _flutter.screenshot
WS_URL=$(echo "$VM_URL" | sed 's|http://|ws://|' | sed 's|/$||')
WS_URL="${WS_URL}/ws"

echo "Connecting to: $WS_URL"

# Use curl to call the VM service HTTP endpoint for screenshot
HTTP_URL=$(echo "$VM_URL" | sed 's|/$||')

# Call the _flutter.screenshot extension method via JSON-RPC
RESPONSE=$(curl -s "${HTTP_URL}/_flutter.screenshot" 2>/dev/null)

if [ -n "$RESPONSE" ]; then
  # Extract base64 image data from JSON response
  echo "$RESPONSE" | python3 -c "
import sys, json, base64
data = json.load(sys.stdin)
if 'result' in data and 'screenshot' in data['result']:
    img_data = base64.b64decode(data['result']['screenshot'])
    with open('${OUTPUT}', 'wb') as f:
        f.write(img_data)
    print(f'Screenshot saved to ${OUTPUT}')
else:
    print(f'Unexpected response: {data}')
" 2>&1
else
  echo "No response from VM service"
fi
