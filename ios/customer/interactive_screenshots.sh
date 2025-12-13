#!/bin/bash

UDID=$(xcrun simctl list devices | grep "Booted" | head -1 | awk -F'[()]' '{print $2}')
SCREENSHOTS_DIR="/Users/nabilimran/Developer/camerons-customer-app/fastlane/screenshots/en-US"
DEVICE="iPhone_16_Pro_Max"

echo "📸 Interactive Screenshot Tool"
echo "==============================="
echo "Simulator UDID: $UDID"
echo ""

screens=("01_Login" "02_Menu" "03_ItemDetail" "04_Cart" "05_Orders" "06_Profile" "07_Rewards")

for screen in "${screens[@]}"; do
    echo ""
    echo "📍 Next screenshot: $screen"
    echo "   Navigate to this screen in Simulator"
    read -p "   Press Enter when ready..."
    
    xcrun simctl io "$UDID" screenshot "$SCREENSHOTS_DIR/${DEVICE}-${screen}.png"
    echo "   ✅ Saved: ${DEVICE}-${screen}.png"
done

echo ""
echo "🎉 All screenshots complete!"
echo ""
ls -la "$SCREENSHOTS_DIR/"
