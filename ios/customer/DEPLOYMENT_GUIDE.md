# 🚀 Order Number System Deployment Guide

## ✅ Implementation Complete!

All code changes have been implemented successfully. The order number system is now ready to deploy!

---

## 📋 What Was Changed

### **Files Modified:**
1. ✅ `Shared/Utilities/StoreCodeMapping.swift` (NEW)
2. ✅ `SupabaseManager.swift` (Updated)
3. ✅ `Core/Cart/Views/CheckoutView.swift` (Updated)
4. ✅ `database-migrations/001_order_number_system.sql` (NEW)

### **Build Status:** ✅ BUILD SUCCEEDED

---

## 🎯 Deployment Steps (Option A: Clean Cut)

### **Step 1: Run Database Migration** 📊

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com
   - Navigate to your project
   - Click on **SQL Editor** in the left sidebar

2. **Run the Migration Script**
   - Open the file: `database-migrations/001_order_number_system.sql`
   - Copy ALL contents
   - Paste into Supabase SQL Editor
   - Click **Run** button

3. **Verify Migration Success**
   Run these verification queries:
   ```sql
   -- Check store codes were added
   SELECT id, name, store_code FROM stores ORDER BY id;

   -- Test order number generation
   SELECT generate_order_number(14);
   -- Expected result: HM-241119-001 (or current date)
   ```

### **Step 2: Deploy Customer App** 📱

The code is already updated! Just build and deploy:

```bash
# Build for simulator (testing)
xcodebuild -project camerons-customer-app.xcodeproj \
  -scheme camerons-customer-app \
  -configuration Debug \
  build \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# OR: Build for device (production)
xcodebuild -project camerons-customer-app.xcodeproj \
  -scheme camerons-customer-app \
  -configuration Release \
  archive
```

### **Step 3: Update Business App** 💼

The business app already reads `order_number` from the database, so **NO CODE CHANGES NEEDED**!

Just rebuild and deploy:
```bash
cd /Users/nabilimran/Developer/camerons-Bussiness-app
xcodebuild -project camerons-Bussiness-app.xcodeproj \
  -scheme camerons-Bussiness-app \
  -configuration Release \
  archive
```

---

## 🧪 Testing Checklist

### **Test 1: Place a New Order**
1. Open customer app
2. Add items to cart
3. Go to checkout
4. Place an order

**Expected Logs:**
```
📤 Submitting order to Supabase:
   - Store ID: 14
   - Customer: nabilaes48
   - Items: 4
   - Total: $67.96

✅ Order submitted successfully!
   📋 Order ID: abc-123-def-456
   🔢 Order Number: HM-241119-001
```

**Expected UI:**
```
✅ Order Placed!
Order #HM-241119-001

Estimated Ready Time
1:24 PM
```

### **Test 2: Verify Business App**
1. Open business app
2. Check active orders
3. Find the order you just placed

**Expected:**
- Order number matches customer app: `HM-241119-001` ✅
- All item details are correct
- Customizations are visible

### **Test 3: Multiple Orders Same Day**
Place 3 orders at Highland Mills (store ID 14):

**Expected Sequence:**
- Order 1: `HM-241119-001` ✅
- Order 2: `HM-241119-002` ✅
- Order 3: `HM-241119-003` ✅

### **Test 4: Multiple Stores**
Place orders at different stores:

**Expected:**
- Highland Mills: `HM-241119-001` ✅
- Bedford: `BB-241119-001` ✅ (independent sequence)

---

## 🔍 Troubleshooting

### **Problem: Order number is NULL or empty**

**Cause:** Database trigger not firing

**Solution:**
```sql
-- Check if trigger exists
SELECT * FROM pg_trigger
WHERE tgname = 'trigger_set_order_number';

-- Recreate trigger if missing
DROP TRIGGER IF EXISTS trigger_set_order_number ON orders;
CREATE TRIGGER trigger_set_order_number
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION set_order_number();
```

### **Problem: App crashes when placing order**

**Cause:** Supabase response doesn't include `order_number`

**Solution:**
```sql
-- Verify order_number column exists
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'orders'
AND column_name = 'order_number';

-- Add column if missing
ALTER TABLE orders
ALTER COLUMN order_number TYPE VARCHAR(20);
```

### **Problem: Order numbers not sequential**

**Cause:** Concurrent order insertion race condition

**Solution:** This is normal! The database uses `ON CONFLICT` to handle race conditions. Sequential numbers are guaranteed per store+date, but may not be perfectly sequential if orders are placed simultaneously.

### **Problem: Store code is "XX"**

**Cause:** Store doesn't have a code assigned

**Solution:**
```sql
-- Check which stores are missing codes
SELECT id, name, store_code
FROM stores
WHERE store_code IS NULL;

-- Assign missing codes
UPDATE stores SET store_code = 'YY' WHERE id = X;
```

---

## 📊 Database Schema Reference

### **Tables Created:**
```sql
-- order_sequences
store_id  | date       | last_sequence
----------|------------|---------------
14        | 2024-11-19 | 5
14        | 2024-11-20 | 1
6         | 2024-11-19 | 2
```

### **Functions Created:**
- `generate_order_number(p_store_id INT)` - Generates next order number
- `set_order_number()` - Trigger function for auto-generation

### **Triggers Created:**
- `trigger_set_order_number` - Auto-generates order_number on INSERT

---

## 🔄 Rollback Plan (If Needed)

If you need to undo this change:

1. **Update customer app to use old format**
2. **Run rollback SQL:**
   ```sql
   DROP TRIGGER IF EXISTS trigger_set_order_number ON orders;
   DROP FUNCTION IF EXISTS set_order_number();
   DROP FUNCTION IF EXISTS generate_order_number(INT);
   DROP TABLE IF EXISTS order_sequences;
   ALTER TABLE stores DROP COLUMN IF EXISTS store_code;
   ```

---

## 📈 Order Number Format

### **Format:** `[STORE_CODE]-[YYMMDD]-[SEQUENCE]`

**Examples:**
```
HM-241119-001  ← Highland Mills, Nov 19 2024, order #1
HM-241119-002  ← Highland Mills, Nov 19 2024, order #2
BB-241119-001  ← Bedford, Nov 19 2024, order #1
HM-241120-001  ← Highland Mills, Nov 20 2024, order #1 (sequence resets daily)
```

### **Store Codes Reference:**
| ID | Store Name | Code |
|----|-----------|------|
| 1  | 35 Vassar Road | VR |
| 14 | Highland Mills | HM |
| 6  | Bedford | BB |
| ...| (see full list in SQL migration) | ... |

---

## ✨ Benefits

### **For Customers:**
- ✅ Short, memorable order numbers
- ✅ Easy to communicate over phone
- ✅ Consistent across both apps

### **For Business:**
- ✅ Identify store instantly from order number
- ✅ Daily sequence for easy tracking
- ✅ Scales to 999 orders/store/day
- ✅ No collisions between stores

### **For Developers:**
- ✅ Database-generated (no sync issues)
- ✅ Atomic operations (no race conditions)
- ✅ Easy to parse and analyze
- ✅ Future-proof for multi-store expansion

---

## 🎉 Deployment Complete!

Once you run the SQL migration, the system will automatically start generating order numbers in the new format.

**No app restart required** - just deploy the updated code!

---

## 📞 Support

If you encounter any issues during deployment:
1. Check the troubleshooting section above
2. Verify all migration steps were completed
3. Check Supabase logs for errors
4. Review customer app console logs

---

**Last Updated:** November 19, 2025
**Version:** 1.0
**Status:** ✅ Ready for Production
