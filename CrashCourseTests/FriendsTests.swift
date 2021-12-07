//	
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import CrashCourse

class FriendsTests: XCTestCase {

    func test_loadFriends_asPremiumUser_withoutConnection_showsError() {
        let service = FriendsAPIStub(result: .success([
            makeFriend(),
            makeFriend()
        ]))
        let sut = TestableListViewController ()
        sut.user = makePremiumUser()
        sut.fromFriendsScreen = true
        sut.friendsService = service

        sut.simulateFirstRequest()
        service.result = .failure(AnyError())
        sut.simulateReloadRequest()

        let errorAlert = sut.presentedVC as? UIAlertController
        XCTAssertEqual(errorAlert?.title, "Error")
    }
}

private struct AnyError: Error {}

private class TestableListViewController: ListViewController {
    var presentedVC: UIViewController?

    override func present(_ vc: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentedVC = vc
    }
}

private extension ListViewController {
    func simulateFirstRequest() {
        loadViewIfNeeded()
        beginAppearanceTransition(true, animated: false)
    }

    func simulateReloadRequest() {
        refreshControl?.sendActions(for: .valueChanged)
    }
}

private func makePremiumUser() -> User {
    User(id: UUID(), name: "a name", isPremium: true)
}

private func makeFriend() -> Friend {
    Friend(id: UUID(), name: "name1", phone: "phone1")
}

private class FriendsAPIStub: FriendsService  {
    var result: Result<[Friend], Error>

    init(result: Result<[Friend], Error>) {
        self.result = result
    }

    func loadFriends(completion: @escaping (Result<[Friend], Error>) -> Void) {
        completion(result)
    }
}
