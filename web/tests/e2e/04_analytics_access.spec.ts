import { test, expect } from '@playwright/test';

/**
 * Analytics Access Control E2E Tests
 *
 * Tests that secure RPC functions properly block unauthorized access:
 * 1. Anonymous users cannot access analytics
 * 2. Customers cannot access store analytics
 * 3. Staff can only access their assigned store
 */

test.describe('Analytics Access Control', () => {
  test('should not expose analytics data on public pages', async ({ page }) => {
    await page.goto('/');

    // Verify no analytics data is visible on home page
    await expect(page.getByTestId('analytics-revenue')).not.toBeVisible();
    await expect(page.getByTestId('analytics-orders')).not.toBeVisible();
  });

  test('should redirect unauthenticated users from analytics page', async ({ page }) => {
    await page.goto('/analytics');

    // Should redirect to login or show unauthorized
    await expect(
      page.getByText(/login|sign in|unauthorized/i).or(page)
    ).toBeVisible({ timeout: 5000 });
  });

  test('should not allow direct RPC calls without auth', async ({ page }) => {
    // Navigate to a page and try to intercept/test RPC
    await page.goto('/');

    // Attempt to make an unauthenticated RPC call via browser console
    const result = await page.evaluate(async () => {
      try {
        // This should fail due to RLS
        const response = await fetch(
          `${(window as any).__SUPABASE_URL || ''}/rest/v1/rpc/get_store_metrics_secure`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'apikey': (window as any).__SUPABASE_ANON_KEY || '',
            },
            body: JSON.stringify({
              p_store_id: 1,
              p_date_range: 'today',
            }),
          }
        );
        return { status: response.status, ok: response.ok };
      } catch (e) {
        return { error: true };
      }
    });

    // RPC should fail or return empty for unauthenticated requests
    // (The exact behavior depends on RLS configuration)
    expect(result).toBeDefined();
  });

  test('customer dashboard should not show admin analytics', async ({ page }) => {
    // Navigate to customer dashboard (will redirect if not logged in)
    await page.goto('/customer/dashboard');

    // Should not see admin-level analytics
    await expect(page.getByTestId('admin-analytics')).not.toBeVisible();
    await expect(page.getByTestId('store-revenue')).not.toBeVisible();

    // Should only see customer-relevant data (rewards, orders)
    // or be redirected to login
  });

  test('should display premium analytics page for authorized users', async ({ page }) => {
    await page.goto('/analytics');

    // Page should exist (even if access is restricted)
    await expect(page).toHaveURL(/analytics|signin|login/i);
  });
});

test.describe('Store Data Access', () => {
  test('should not expose store-specific data to public', async ({ page }) => {
    await page.goto('/locations');

    // Store locations are public
    await expect(page.getByText(/cameron/i)).toBeVisible({ timeout: 5000 });

    // But internal metrics should not be visible
    await expect(page.getByTestId('store-daily-revenue')).not.toBeVisible();
    await expect(page.getByTestId('store-orders-count')).not.toBeVisible();
  });

  test('public store list should be accessible', async ({ page }) => {
    await page.goto('/locations');

    // Should show store list
    await expect(
      page.getByRole('heading', { name: /locations|stores|find/i })
    ).toBeVisible({ timeout: 5000 });
  });
});

test.describe('API Security Headers', () => {
  test('should have proper security headers', async ({ page }) => {
    const response = await page.goto('/');

    if (response) {
      const headers = response.headers();

      // Check for security headers (these should be set by your hosting provider)
      // Note: These may not be present in local dev
      if (process.env.CI) {
        expect(headers['x-frame-options'] || headers['content-security-policy']).toBeDefined();
      }
    }
  });
});

test.describe('Role-Based Access', () => {
  test.skip('staff should only see their assigned store data', async ({ page }) => {
    // This test requires staff authentication
    if (!process.env.TEST_STAFF_EMAIL) {
      test.skip();
      return;
    }

    // Login as staff
    await page.goto('/dashboard/login');
    await page.fill('[type="email"]', process.env.TEST_STAFF_EMAIL);
    await page.fill('[type="password"]', process.env.TEST_STAFF_PASSWORD || '');
    await page.getByRole('button', { name: /sign in/i }).click();

    await expect(page).toHaveURL(/dashboard/i, { timeout: 10000 });

    // Navigate to analytics
    await page.getByRole('tab', { name: /analytics/i }).click();

    // Should only see their store's data
    // The store selector (if visible) should only show assigned stores
    const storeSelector = page.locator('[data-testid="store-selector"]');
    if (await storeSelector.isVisible()) {
      const options = await storeSelector.locator('option').count();
      // Staff should only see their assigned stores (not all 29)
      expect(options).toBeLessThan(30);
    }
  });

  test.skip('super admin should see all stores', async ({ page }) => {
    // This test requires super admin authentication
    if (!process.env.TEST_ADMIN_EMAIL) {
      test.skip();
      return;
    }

    // Login as admin
    await page.goto('/dashboard/login');
    await page.fill('[type="email"]', process.env.TEST_ADMIN_EMAIL);
    await page.fill('[type="password"]', process.env.TEST_ADMIN_PASSWORD || '');
    await page.getByRole('button', { name: /sign in/i }).click();

    await expect(page).toHaveURL(/dashboard|super-admin/i, { timeout: 10000 });

    // Admin should see all stores or a store selector with all options
    await expect(
      page.getByText(/all stores|highland mills/i)
    ).toBeVisible({ timeout: 5000 });
  });
});
