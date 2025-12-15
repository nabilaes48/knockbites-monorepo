# RLS Policy Audit Report

**Date:** December 14, 2025
**Project:** KnockBites
**Database:** Supabase (dsmefhuhflixoevexafm)

---

## Executive Summary

Comprehensive audit and cleanup of Row Level Security (RLS) policies across all tables. Fixed critical security vulnerabilities and removed redundant policies to improve performance and maintainability.

---

## Critical Security Fixes

### 1. Orders Table - Anonymous Access Vulnerability

**Problem:** `guest_track_order_by_id` policy had `USING (true)` which allowed anonymous users to view ALL orders in the system.

**Fix:** Removed the policy. Anonymous users must now provide a valid `tracking_token` to view orders.

```sql
-- REMOVED (was exposing all orders)
DROP POLICY "guest_track_order_by_id" ON orders;

-- KEPT (secure - requires token)
-- orders_select_by_token_anon: tracking_token = get_request_tracking_token()
```

### 2. Order Items Table - Data Exposure

**Problem:** Two policies (`guest_view_order_items` and `Order items viewable with order`) had `USING (true)` exposing all order items to everyone.

**Fix:** Removed both policies. Order items are now only visible if user has access to the parent order.

```sql
DROP POLICY "guest_view_order_items" ON order_items;
DROP POLICY "Order items viewable with order" ON order_items;
```

### 3. Auth.users Access Error

**Problem:** `orders_select_customer` policy was accessing `auth.users` table directly, causing "permission denied for table users" error when customers tried to place orders.

**Fix:** Simplified to use `auth.uid()` directly without accessing `auth.users`.

```sql
-- Before (caused errors)
USING (customer_email = (SELECT email FROM auth.users WHERE id = auth.uid()))

-- After (fixed)
USING (customer_id = auth.uid() OR user_id = auth.uid())
```

### 4. Order Items SELECT Complexity

**Problem:** `order_items_select_with_order` had complex nested query accessing `auth.users`.

**Fix:** Simplified to check order ownership without accessing `auth.users`.

---

## Redundant Policies Removed

### Orders Table (5 removed)
| Policy Name | Reason |
|-------------|--------|
| `Users can view their own orders` | Duplicate of `orders_select_customer` |
| `customers_view_orders_by_email` | Duplicate functionality |
| `customers_view_own_orders` | Duplicate functionality |
| `admin_view_store_orders` | Covered by `orders_select_staff` |
| `staff_view_store_orders` | Covered by `orders_select_staff` |

### Menu Items Table (2 removed)
| Policy Name | Reason |
|-------------|--------|
| `Menu items viewable by everyone` | Duplicate of `Allow anonymous read menu_items` |
| `rbac_public_view_menu_items` | Duplicate functionality |

### Customer Rewards Table (2 removed)
| Policy Name | Reason |
|-------------|--------|
| `Staff can view customer rewards` | Duplicate of `Staff can view all rewards` |
| `Customers view own rewards` | Duplicate of `Customers can view their own rewards` |

### Rewards Transactions Table (3 removed)
| Policy Name | Reason |
|-------------|--------|
| `Staff can view transactions` | Duplicate of `Staff can view all transactions` |
| `Customers view own transactions` | Duplicate functionality |
| `System can manage transactions` | Duplicate of `Super admin can manage transactions` |

### Stores Table (2 removed)
| Policy Name | Reason |
|-------------|--------|
| `stores_modify_admin` | Duplicate of `super_admin_manage_all_stores` |
| `Stores are viewable by everyone` | Duplicate of `stores_select_public` |

---

## Current Policy Structure

### Orders Table (6 policies)
| Policy | Command | Description |
|--------|---------|-------------|
| `orders_insert_public` | INSERT | Anyone can create orders |
| `orders_select_by_token_anon` | SELECT | Anon needs tracking token |
| `orders_select_customer` | SELECT | Customers see own orders |
| `orders_select_staff` | SELECT | Staff see store orders |
| `super_admin_view_all_orders` | SELECT | Super admin sees all |
| `orders_update_staff_only` | UPDATE | Only staff can update |

### Order Items Table (3 policies)
| Policy | Command | Description |
|--------|---------|-------------|
| `guest_checkout_create_order_items` | INSERT | Anyone can create |
| `order_items_select_with_order` | SELECT | Based on order access |
| `Staff can update order items` | UPDATE | Staff only |

### Customers Table (4 policies)
| Policy | Command | Description |
|--------|---------|-------------|
| `public_insert_customers` | INSERT | Anyone can create |
| `customers_view_own` | SELECT | View own profile |
| `staff_view_customers` | SELECT | Staff can view all |
| `customers_update_own` | UPDATE | Update own profile |

### Menu Items Table (7 policies)
| Policy | Command | Description |
|--------|---------|-------------|
| `super_admin_manage_menu` | ALL | Super admin full access |
| `admin_manage_store_menu` | ALL | Admin full access |
| `Staff can delete menu items` | DELETE | Manager+ can delete |
| `Staff can insert menu items` | INSERT | Manager+ can insert |
| `Allow anonymous read menu_items` | SELECT | Public can view available |
| `Staff can update menu items` | UPDATE | Manager+ can update |
| `manager_update_menu_availability` | UPDATE | Manager can toggle availability |

### Stores Table (3 policies)
| Policy | Command | Description |
|--------|---------|-------------|
| `super_admin_manage_all_stores` | ALL | Super admin full access |
| `stores_select_public` | SELECT | Everyone can view |
| `admin_update_their_stores` | UPDATE | Admins update assigned stores |

---

## Policy Count Summary

| Table | Before | After |
|-------|--------|-------|
| orders | 11 | 6 |
| order_items | 5 | 3 |
| menu_items | 9 | 7 |
| customer_rewards | 6 | 4 |
| rewards_transactions | 6 | 3 |
| stores | 5 | 3 |
| **Total** | **~70** | **~55** |

---

## Migration File Created

A migration file was created for future reference:
```
supabase/migrations/071_fix_customer_order_insert.sql
```

---

## Recommendations

1. **Regular Audits:** Review RLS policies quarterly
2. **Avoid auth.users Access:** Use `auth.uid()` instead of querying `auth.users`
3. **Single Responsibility:** Each policy should have one clear purpose
4. **Test After Changes:** Always test order flow after policy changes
5. **Document Policies:** Keep this document updated when adding new policies

---

## Testing Checklist

After policy changes, verify:

- [ ] Anonymous can browse menu
- [ ] Anonymous can create orders (guest checkout)
- [ ] Customers can sign up/sign in
- [ ] Customers can view their own orders
- [ ] Customers can place orders
- [ ] Staff can view store orders
- [ ] Staff can update order status
- [ ] Admin can manage menu items
- [ ] Super admin has full access

---

*Generated by Claude Code on December 14, 2025*
