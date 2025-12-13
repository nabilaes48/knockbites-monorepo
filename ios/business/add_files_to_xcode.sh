#!/bin/bash
echo "To add files to Xcode:"
echo "1. In Xcode, right-click 'camerons-Bussiness-app' folder"
echo "2. Select 'Add Files to...'"
echo "3. Select the Core and Shared folders"
echo "4. Make sure target is checked"
echo "5. Click Add"
echo ""
echo "Files to add:"
find camerons-Bussiness-app/Core -name "*.swift" -type f
find camerons-Bussiness-app/Shared -name "*.swift" -type f
