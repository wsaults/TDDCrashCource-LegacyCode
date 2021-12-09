//	
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import CrashCourse

/*
- Load friends from API on viewWillAppear
- If Successful: show friends
- If failed:
    - Retry twice
        - If all retries fail: show error
        - If a retry succeeds: show friends
 - On selection: Show friend details
 */

class FriendsViewController: UIViewController {
    private let service: FriendsService

    init(service: FriendsService) {
        self.service = service
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        service.loadFriends { _ in
            
        }
    }
}

class FriendsServiceSpy: FriendsService {
    private(set) var loadFriendsCallCount = 0

    func loadFriends(completion: @escaping (Result<[Friend], Error>) -> Void) {
        loadFriendsCallCount += 1
    }
}

class FriendsTests: XCTestCase {

    func test_viewDidLoad_doesNotLoadFriendsFromAPI() {
        let service = FriendsServiceSpy()
        let sut = FriendsViewController(service: service)

        sut.loadViewIfNeeded()

        XCTAssertEqual(service.loadFriendsCallCount, 0)
    }

    func test_viewWillAppear_loadsFriendsFromAPI() {
        let service = FriendsServiceSpy()
        let sut = FriendsViewController(service: service)

        sut.loadViewIfNeeded()
        sut.beginAppearanceTransition(true, animated: false)

        XCTAssertEqual(service.loadFriendsCallCount, 1)
    }
}
