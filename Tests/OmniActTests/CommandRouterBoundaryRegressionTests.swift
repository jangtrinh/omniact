import XCTest
@testable import OmniAct

final class CommandRouterBoundaryRegressionTests: XCTestCase {
    func testSlashTokenDoesNotMatchLongerToken() {
        let router = CommandRouter(catalog: MutableCommandCatalog(FactoryCommandCatalog.commands))
        let (command, argument) = router.resolveCommand(from: "/fixx keep this raw")

        XCTAssertNil(command)
        XCTAssertEqual(argument, "/fixx keep this raw")
    }
}
