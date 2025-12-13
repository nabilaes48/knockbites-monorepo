#!/bin/bash

UDID="5DC37AC3-883C-489E-AB87-7E6DBEEE1266"
SCREENSHOTS_DIR="/Users/nabilimran/Developer/camerons-customer-app/fastlane/screenshots/en-US"

echo "📸 Screenshot Helper"
echo "===================="
echo ""
echo "This will take screenshots with a 5-second delay."
echo "Navigate to the desired screen in Simulator before each screenshot."
echo ""

screens=("01_Login" "02_Menu" "03_ItemDetail" "04_Cart" "05_Orders" "06_Profile" "07_Rewards")

for screen in "${screens[@]}"; do
    echo "Next: $screen"
    echo "Navigate to this screen in Simulator..."
    echo "Taking screenshot in 5 seconds..."
    sleep 5
    xcrun simctl io "$UDID" screenshot "$SCREENSHOTS_DIR/iPhone_16_Pro_Max-$screen.png"
    echo "✅ Saved: iPhone_16_Pro_Max-$screen.png"
    echo ""
done

echo "📸 All screenshots complete!"
ls -la "$SCREENSHOTS_DIR/"
