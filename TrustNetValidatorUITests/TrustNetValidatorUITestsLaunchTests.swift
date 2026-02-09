import XCTest

final class TrustNetValidatorUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Take a screenshot after launch
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screenshot"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
