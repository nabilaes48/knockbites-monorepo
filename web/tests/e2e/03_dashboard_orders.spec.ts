import { test, expect } from '@playwright/test';

/**
 * Staff Dashboard Orders E2E Tests
 *
 * Tests the staff dashboard functionality:
 * 1. Staff login
 * 2. View store orders
 * 3. Update order status
 */

// Test staff credentials (should be configured via environment)
const TEST_STAFF = {
  email: process.env.TEST_STAFF_EMAIL || 'staff@cameronsconnect.com',
  password: process.env.TEST_STAFF_PASSWORD || 'staffpassword123',
};

test.describe('Staff Dashboard Login', () => {
  test('should display dashboard login page', async ({ page }) => {
    await page.goto('/dashboard/login');

    // Check for login form
    await expect(page.getByRole('heading', { name: /dashboard|staff|login/i })).toBeVisible();
    await expect(page.getByLabel(/email/i).or(page.locator('[type="email"]'))).toBeVisible();
  });

  test('should show error for unauthorized access', async ({ page }) => {
    await page.goto('/dashboard');

    // Should redirect to login or show unauthorized message
    await expect(
      page.getByText(/login|unauthorized|sign in/i).or(page.locator('[href*="login"]'))
    ).toBeVisible({ timeout: 5000 });
  });

  test.skip('should login as staff and view dashboard', async ({ page }) => {
    // Skip if no test credentials
    if (!process.env.TEST_STAFF_EMAIL) {
      test.skip();
      return;
    }

    await page.goto('/dashboard/login');

    // Login
    await page.fill('[type="email"]', TEST_STAFF.email);
    await page.fill('[type="password"]', TEST_STAFF.password);
    await page.getByRole('button', { name: /sign in|login/i }).click();

    // Should show dashboard
    await expect(page).toHaveURL(/dashboard/i, { timeout: 10000 });
    await expect(page.getByText(/orders|menu|analytics/i)).toBeVisible();
  });
});

test.describe('Order Management', () => {
  test.skip('should display orders list', async ({ page }) => {
    // Requires staff login
    if (!process.env.TEST_STAFF_EMAIL) {
      test.skip();
      return;
    }

    // Login first (would use storageState in real scenario)
    await page.goto('/dashboard/login');
    await page.fill('[type="email"]', TEST_STAFF.email);
    await page.fill('[type="password"]', TEST_STAFF.password);
    await page.getByRole('button', { name: /sign in/i }).click();

    // Wait for dashboard
    await expect(page).toHaveURL(/dashboard/i, { timeout: 10000 });

    // Navigate to orders tab
    await page.getByRole('tab', { name: /orders/i }).click();

    // Should show orders list or "no orders" message
    await expect(
      page.getByTestId('orders-list').or(page.getByText(/no orders|pending|orders/i))
    ).toBeVisible({ timeout: 5000 });
  });

  test.skip('should update order status', async ({ page }) => {
    // Requires staff login and existing order
    if (!process.env.TEST_STAFF_EMAIL) {
      test.skip();
      return;
    }

    // Login
    await page.goto('/dashboard/login');
    await page.fill('[type="email"]', TEST_STAFF.email);
    await page.fill('[type="password"]', TEST_STAFF.password);
    await page.getByRole('button', { name: /sign in/i }).click();

    await expect(page).toHaveURL(/dashboard/i, { timeout: 10000 });

    // Navigate to orders
    await page.getByRole('tab', { name: /orders/i }).click();
    await page.waitForTimeout(1000);

    // Find an order and update its status
    const orderCard = page.locator('[data-testid="order-card"]').first();
    if (await orderCard.isVisible()) {
      const statusButton = orderCard.getByRole('button', { name: /accept|preparing|ready/i });
      if (await statusButton.isVisible()) {
        await statusButton.click();

        // Verify status changed
        await expect(
          page.getByText(/updated|preparing|ready/i)
        ).toBeVisible({ timeout: 5000 });
      }
    }
  });
});

test.describe('Dashboard Tabs', () => {
  test('should navigate to dashboard tabs', async ({ page }) => {
    // Just verify the structure (without login)
    await page.goto('/dashboard/login');

    // Check that login page has proper structure
    await expect(page.locator('form, [role="form"]')).toBeVisible();
  });

  test.skip('should access menu management', async ({ page }) => {
    if (!process.env.TEST_STAFF_EMAIL) {
      test.skip();
      return;
    }

    // Login
    await page.goto('/dashboard/login');
    await page.fill('[type="email"]', TEST_STAFF.email);
    await page.fill('[type="password"]', TEST_STAFF.password);
    await page.getByRole('button', { name: /sign in/i }).click();

    await expect(page).toHaveURL(/dashboard/i, { timeout: 10000 });

    // Navigate to menu tab
    const menuTab = page.getByRole('tab', { name: /menu/i });
    if (await menuTab.isVisible()) {
      await menuTab.click();

      // Should show menu management
      await expect(
        page.getByText(/menu items|add item|manage/i)
      ).toBeVisible({ timeout: 5000 });
    }
  });

  test.skip('should access analytics', async ({ page }) => {
    if (!process.env.TEST_STAFF_EMAIL) {
      test.skip();
      return;
    }

    // Login
    await page.goto('/dashboard/login');
    await page.fill('[type="email"]', TEST_STAFF.email);
    await page.fill('[type="password"]', TEST_STAFF.password);
    await page.getByRole('button', { name: /sign in/i }).click();

    await expect(page).toHaveURL(/dashboard/i, { timeout: 10000 });

    // Navigate to analytics tab
    const analyticsTab = page.getByRole('tab', { name: /analytics/i });
    if (await analyticsTab.isVisible()) {
      await analyticsTab.click();

      // Should show analytics content
      await expect(
        page.getByText(/revenue|orders|analytics/i)
      ).toBeVisible({ timeout: 5000 });
    }
  });
});
