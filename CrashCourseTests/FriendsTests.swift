//	
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import CrashCourse

/*
x Load friends from API on viewWillAppear
x If Successful: show friends
- If failed:
    - Retry twice
        - If all retries fail: show error
        - If a retry succeeds: show friends
 - On selection: Show friend details
 */

class FriendsViewController: UITableViewController {
    private let service: FriendsService
    private var friends: [Friend] = [] {
        didSet { tableView.reloadData() }
    }

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

        service.loadFriends { result in
            switch result {
            case let .success(friends):
                self.friends = friends
            case .failure:
                self.service.loadFriends { result in
                    switch result {
                    case .success:
                        break
                    case .failure:
                        self.service.loadFriends { result in
                            switch result {
                            case .success:
                                break
                            case let .failure(error):
                                self.show(error)
                            }
                        }
                    }
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        friends.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let friend = friends[indexPath.row]
        cell.textLabel?.text = friend.name
        cell.detailTextLabel?.text = friend.phone
        return cell
    }
}

class FriendsServiceSpy: FriendsService {
    private(set) var loadFriendsCallCount = 0
    private var results: [Result<[Friend], Error>]

    init(result: [Friend] = []) {
        self.results = [.success(result)]
    }

    init(results: [Result<[Friend], Error>]) {
        self.results = results
    }

    func loadFriends(completion: @escaping (Result<[Friend], Error>) -> Void) {
        loadFriendsCallCount += 1
        completion(results.removeFirst())
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

        sut.simulateViewWillAppear()

        XCTAssertEqual(service.loadFriendsCallCount, 1)
    }

    func test_viewWillAppear_successfulAPIResponse_showsFriends() {
        let friend1 = Friend(id: UUID(), name: "friend1", phone: "phone1")
        let friend2 = Friend(id: UUID(), name: "friend2", phone: "phone2")
        let service = FriendsServiceSpy(result: [friend1, friend2])
        let sut = FriendsViewController(service: service)

        sut.simulateViewWillAppear()

        XCTAssertEqual(sut.numberOfFriends(), 2)

        XCTAssertEqual(sut.friendName(at: 0), friend1.name)
        XCTAssertEqual(sut.friendPhone(at: 0), friend1.phone)
        XCTAssertEqual(sut.friendName(at: 1), friend2.name)
        XCTAssertEqual(sut.friendPhone(at: 1), friend2.phone)
    }

    func test_viewWillAppear_failedAPIResponse_3times_showsError() {
        let service = FriendsServiceSpy(results: [
            .failure(AnyError(errorDescription: "1st error")),
            .failure(AnyError(errorDescription: "2nd error")),
            .failure(AnyError(errorDescription: "3rd error"))
        ])
        let sut = TestableFriendsViewController(service: service)

        sut.simulateViewWillAppear()

        XCTAssertEqual(sut.errorMessage(), "3rd error")
    }
}

private struct AnyError: LocalizedError {
    var errorDescription: String?
}

private class TestableFriendsViewController: FriendsViewController {
    var presentedVC: UIViewController?

    override func present(_ vc: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentedVC = vc
    }

    func errorMessage() -> String? {
        let alert = presentedVC as? UIAlertController
        return alert?.message
    }
}

private extension FriendsViewController {
    func simulateViewWillAppear() {
        loadViewIfNeeded()
        beginAppearanceTransition(true, animated: false)
    }

    func numberOfFriends() -> Int {
        tableView.numberOfRows(inSection: friendsSection)
    }

    func friendName(at row: Int) -> String? {
        friendCell(at: row)?.textLabel?.text
    }

    func friendPhone(at row: Int) -> String? {
        friendCell(at: row)?.detailTextLabel?.text
    }

    private func friendCell(at row: Int) -> UITableViewCell? {
        let indexPath = IndexPath(row: row, section: friendsSection)
        return tableView.dataSource?.tableView(tableView, cellForRowAt: indexPath)
    }

    private var friendsSection: Int { 0 }
}
