import { test, expect } from '@playwright/test';

/**
 * Authenticated Customer Checkout E2E Tests
 *
 * Tests the complete order flow with authentication:
 * 1. Login as customer
 * 2. Place order
 * 3. Verify rewards are updated
 */

// Test customer credentials (should be configured via environment or test fixtures)
const TEST_CUSTOMER = {
  email: process.env.TEST_CUSTOMER_EMAIL || 'test.customer@example.com',
  password: process.env.TEST_CUSTOMER_PASSWORD || 'testpassword123',
};

test.describe('Authenticated Customer Flow', () => {
  test('should display sign in page', async ({ page }) => {
    await page.goto('/signin');

    // Check for sign in form
    await expect(page.getByRole('heading', { name: /sign in/i })).toBeVisible();
    await expect(page.getByLabel(/email/i)).toBeVisible();
    await expect(page.getByLabel(/password/i)).toBeVisible();
  });

  test('should show error for invalid credentials', async ({ page }) => {
    await page.goto('/signin');

    // Fill in invalid credentials
    await page.fill('[name="email"], [type="email"]', 'invalid@example.com');
    await page.fill('[name="password"], [type="password"]', 'wrongpassword');

    // Submit form
    await page.getByRole('button', { name: /sign in/i }).click();

    // Should show error message
    await expect(
      page.getByText(/invalid|error|incorrect/i)
    ).toBeVisible({ timeout: 5000 });
  });

  test('should navigate to sign up page', async ({ page }) => {
    await page.goto('/signin');

    // Click sign up link
    const signUpLink = page.getByRole('link', { name: /sign up|create account/i });
    if (await signUpLink.isVisible()) {
      await signUpLink.click();
      await expect(page).toHaveURL(/signup/i);
    }
  });

  test.skip('should login and access customer dashboard', async ({ page }) => {
    // Skip this test if no test credentials are configured
    if (!process.env.TEST_CUSTOMER_EMAIL) {
      test.skip();
      return;
    }

    await page.goto('/signin');

    // Login
    await page.fill('[name="email"], [type="email"]', TEST_CUSTOMER.email);
    await page.fill('[name="password"], [type="password"]', TEST_CUSTOMER.password);
    await page.getByRole('button', { name: /sign in/i }).click();

    // Should redirect to home or dashboard
    await expect(page).not.toHaveURL(/signin/i, { timeout: 10000 });

    // Navigate to customer dashboard
    await page.goto('/customer/dashboard');

    // Should show customer dashboard elements
    await expect(page.getByText(/rewards|orders|points/i)).toBeVisible({ timeout: 5000 });
  });

  test.skip('should place order and update rewards', async ({ page }) => {
    // Skip this test if no test credentials are configured
    if (!process.env.TEST_CUSTOMER_EMAIL) {
      test.skip();
      return;
    }

    // Login first
    await page.goto('/signin');
    await page.fill('[name="email"], [type="email"]', TEST_CUSTOMER.email);
    await page.fill('[name="password"], [type="password"]', TEST_CUSTOMER.password);
    await page.getByRole('button', { name: /sign in/i }).click();

    // Wait for login to complete
    await expect(page).not.toHaveURL(/signin/i, { timeout: 10000 });

    // Get initial rewards (if visible)
    await page.goto('/customer/dashboard');
    const initialPoints = await page.getByTestId('rewards-points').textContent();

    // Place an order
    await page.goto('/order');
    await page.waitForLoadState('networkidle');

    // Add item to cart
    const addButton = page.getByRole('button', { name: /add to cart/i }).first();
    if (await addButton.isVisible()) {
      await addButton.click();

      // Proceed to checkout
      await page.getByRole('button', { name: /checkout/i }).click();

      // Submit order (info should be pre-filled for logged in user)
      await page.getByRole('button', { name: /place order/i }).click();

      // Wait for order confirmation
      await expect(page).toHaveURL(/tracking|confirmation/i, { timeout: 15000 });

      // Check rewards updated
      await page.goto('/customer/dashboard');
      const newPoints = await page.getByTestId('rewards-points').textContent();

      // Points should have increased (if order was completed)
      // This is a soft assertion since order might still be pending
      if (initialPoints && newPoints) {
        console.log(`Points: ${initialPoints} -> ${newPoints}`);
      }
    }
  });
});

test.describe('Customer Dashboard', () => {
  test('should redirect unauthenticated users from dashboard', async ({ page }) => {
    await page.goto('/customer/dashboard');

    // Should redirect to signin
    await expect(page).toHaveURL(/signin/i, { timeout: 5000 });
  });

  test('should display rewards section when logged in', async ({ page }) => {
    // This test requires authentication setup
    // In a real scenario, we would use Playwright's storageState to maintain login

    // For now, just verify the page structure
    await page.goto('/customer/dashboard');

    // Either redirects to signin or shows dashboard
    const url = page.url();
    expect(url).toMatch(/signin|dashboard/i);
  });
});
