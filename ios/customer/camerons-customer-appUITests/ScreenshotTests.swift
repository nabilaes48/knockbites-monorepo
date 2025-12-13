//
//  ScreenshotTests.swift
//  knockbites-customer-appUITests
//
//  Screenshot automation for App Store
//

import XCTest

@MainActor
final class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Set up snapshot helper
        setupSnapshot(app)

        // Launch arguments for testing
        app.launchArguments += ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Screenshot Tests

    func testTakeAppStoreScreenshots() throws {
        // Screenshot 1: Login/Welcome Screen
        sleep(2) // Wait for app to load
        snapshot("01_Welcome")

        // Try to login or skip if already logged in
        loginIfNeeded()

        // Screenshot 2: Store Selection
        sleep(2)
        if app.staticTexts["Select a Store"].waitForExistence(timeout: 5) {
            snapshot("02_StoreSelection")

            // Select first store
            let storeCell = app.cells.firstMatch
            if storeCell.exists {
                storeCell.tap()
                sleep(1)
            }
        }

        // Screenshot 3: Main Menu
        sleep(2)
        snapshot("03_Menu")

        // Screenshot 4: Item Detail
        // Tap on first menu item
        let menuItem = app.cells.firstMatch
        if menuItem.waitForExistence(timeout: 5) {
            menuItem.tap()
            sleep(2)
            snapshot("04_ItemDetail")

            // Go back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
                sleep(1)
            }
        }

        // Screenshot 5: Cart (navigate to cart tab)
        let cartTab = app.tabBars.buttons["Cart"]
        if cartTab.exists {
            cartTab.tap()
            sleep(2)
            snapshot("05_Cart")
        }

        // Screenshot 6: Favorites
        let favoritesTab = app.tabBars.buttons["Favorites"]
        if favoritesTab.exists {
            favoritesTab.tap()
            sleep(2)
            snapshot("06_Favorites")
        }

        // Screenshot 7: Orders
        let ordersTab = app.tabBars.buttons["Orders"]
        if ordersTab.exists {
            ordersTab.tap()
            sleep(2)
            snapshot("07_Orders")
        }

        // Screenshot 8: Profile
        let profileTab = app.tabBars.buttons["Profile"]
        if profileTab.exists {
            profileTab.tap()
            sleep(2)
            snapshot("08_Profile")
        }

        // Screenshot 9: Go back to Menu for a clean final shot
        let menuTab = app.tabBars.buttons["Menu"]
        if menuTab.exists {
            menuTab.tap()
            sleep(2)
            snapshot("09_MenuFinal")
        }
    }

    // MARK: - Helper Methods

    private func loginIfNeeded() {
        // Check if we're on login screen
        let emailField = app.textFields["Email"]
        let loginButton = app.buttons["Sign In"]

        if emailField.waitForExistence(timeout: 3) {
            // We're on login screen, enter test credentials
            emailField.tap()
            emailField.typeText("test@knockbites.com")

            let passwordField = app.secureTextFields["Password"]
            if passwordField.exists {
                passwordField.tap()
                passwordField.typeText("TestPassword123")
            }

            if loginButton.exists {
                loginButton.tap()
                sleep(3) // Wait for login
            }
        }
    }
}

// MARK: - Snapshot Helper Functions

func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
    // Check if running in fastlane snapshot mode
    if ProcessInfo.processInfo.environment["FASTLANE_SNAPSHOT"] != nil {
        // Running with fastlane
        app.launchArguments += ["FASTLANE_SNAPSHOT"]
    }
}

func snapshot(_ name: String, waitForLoadingIndicator: Bool = true) {
    // Take screenshot and save
    let screenshot = XCUIScreen.main.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = name
    attachment.lifetime = .keepAlways

    // Save to disk for fastlane
    let fileManager = FileManager.default

    // Try to find the screenshots directory
    if let simulatorHome = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] {
        let screenshotsPath = "\(simulatorHome)/Library/Caches/tools.fastlane/screenshots"

        do {
            try fileManager.createDirectory(atPath: screenshotsPath, withIntermediateDirectories: true)
            let filePath = "\(screenshotsPath)/\(name).png"
            try screenshot.pngRepresentation.write(to: URL(fileURLWithPath: filePath))
            NSLog("Snapshot saved: \(filePath)")
        } catch {
            NSLog("Failed to save snapshot: \(error)")
        }
    }
}
