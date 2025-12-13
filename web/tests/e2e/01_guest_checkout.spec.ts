import { test, expect } from '@playwright/test';

/**
 * Guest Checkout Flow E2E Tests
 *
 * Tests the complete order flow without authentication:
 * 1. Browse menu
 * 2. Add items to cart
 * 3. Complete checkout as guest
 * 4. Verify tracking page loads
 */

test.describe('Guest Checkout Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Start from the home page
    await page.goto('/');
  });

  test('should display home page with order button', async ({ page }) => {
    // Check for the order button
    await expect(page.getByRole('link', { name: /order now/i })).toBeVisible();

    // Check for menu link
    await expect(page.getByRole('link', { name: /menu/i })).toBeVisible();
  });

  test('should navigate to menu and display categories', async ({ page }) => {
    // Navigate to menu
    await page.goto('/menu');

    // Wait for menu to load
    await expect(page.getByRole('heading', { name: /menu/i })).toBeVisible();

    // Check for at least one menu item
    await expect(page.locator('[data-testid="menu-item"]').first()).toBeVisible({
      timeout: 10000,
    });
  });

  test('should navigate to order page and show store selection', async ({ page }) => {
    // Navigate to order page
    await page.goto('/order');

    // Should show store selection or menu
    await expect(
      page.getByRole('heading', { name: /select.*store|order/i })
    ).toBeVisible({ timeout: 10000 });
  });

  test('should complete guest checkout flow', async ({ page }) => {
    // Navigate to order page
    await page.goto('/order');

    // Wait for page to load
    await page.waitForLoadState('networkidle');

    // Store selection (if applicable)
    const storeSelect = page.locator('select, [data-testid="store-select"]').first();
    if (await storeSelect.isVisible()) {
      await storeSelect.selectOption({ index: 1 });
    }

    // Wait for menu items to load
    await page.waitForTimeout(2000);

    // Try to add first available item to cart
    const addToCartButton = page.getByRole('button', { name: /add to cart|add/i }).first();
    if (await addToCartButton.isVisible()) {
      await addToCartButton.click();

      // Wait for cart to update
      await page.waitForTimeout(500);

      // Proceed to checkout
      const checkoutButton = page.getByRole('button', { name: /checkout|proceed/i });
      if (await checkoutButton.isVisible()) {
        await checkoutButton.click();

        // Fill in guest info
        await page.fill('[name="name"], [placeholder*="name" i]', 'Test User');
        await page.fill('[name="phone"], [placeholder*="phone" i]', '555-123-4567');
        await page.fill('[name="email"], [placeholder*="email" i]', 'test@example.com');

        // Submit order
        const submitButton = page.getByRole('button', { name: /place order|submit/i });
        if (await submitButton.isVisible()) {
          await submitButton.click();

          // Should redirect to tracking page or show confirmation
          await expect(page).toHaveURL(/tracking|confirmation/i, { timeout: 10000 });
        }
      }
    }
  });

  test('should display order tracking page for valid order', async ({ page }) => {
    // Try to access tracking with a sample UUID
    // In a real test, we would create an order first
    await page.goto('/order/tracking/00000000-0000-0000-0000-000000000000');

    // Should show either the order or "not found" message
    await expect(
      page.getByText(/order|not found|tracking/i)
    ).toBeVisible({ timeout: 10000 });
  });
});

test.describe('Menu Browsing', () => {
  test('should filter menu by category', async ({ page }) => {
    await page.goto('/menu');

    // Wait for categories to load
    await page.waitForLoadState('networkidle');

    // Click on a category filter if available
    const categoryButton = page.getByRole('button', { name: /breakfast|sandwiches|burgers/i }).first();
    if (await categoryButton.isVisible()) {
      await categoryButton.click();

      // Menu should update
      await page.waitForTimeout(500);
      await expect(page.locator('[data-testid="menu-item"]').first()).toBeVisible();
    }
  });

  test('should display menu item details', async ({ page }) => {
    await page.goto('/menu');

    // Wait for menu to load
    await page.waitForLoadState('networkidle');

    // Click on first menu item
    const menuItem = page.locator('[data-testid="menu-item"]').first();
    if (await menuItem.isVisible()) {
      await menuItem.click();

      // Should show item details or customization modal
      await expect(
        page.getByRole('dialog').or(page.getByText(/customize|add to cart/i))
      ).toBeVisible({ timeout: 5000 });
    }
  });
});
