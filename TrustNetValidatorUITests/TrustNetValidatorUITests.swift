import XCTest

final class TrustNetValidatorUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testAppLaunchAndTestExecution() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify the app title is visible
        XCTAssertTrue(app.staticTexts["TrustNet"].exists, "App title should be visible")
        
        // Find and tap the Run Tests button
        let runButton = app.buttons["Run Tests"]
        XCTAssertTrue(runButton.exists, "Run Tests button should exist")
        
        runButton.tap()
        
        // Wait for tests to complete (up to 10 seconds)
        let testsPassed = app.staticTexts["All Tests Passed!"]
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == 1"), object: testsPassed)
        let result = XCTWaiter.wait(for: [expectation], timeout: 10.0)
        
        XCTAssertEqual(result, .completed, "Tests should complete successfully")
    }
    
    func testUIElementsPresent() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Check for key UI elements
        XCTAssertTrue(app.staticTexts["PassportValidator Test Suite"].exists)
        XCTAssertTrue(app.buttons["Run Tests"].exists)
        XCTAssertTrue(app.navigationBars.firstMatch.exists)
    }
}
