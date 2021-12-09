//	
// Copyright © Essential Developer. All rights reserved.
//

import XCTest
@testable import CrashCourse

/*
x Load friends from API on viewWillAppear
- If Successful: show friends
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
                break
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
    private let result: Result<[Friend], Error>

    init(result: [Friend] = []) {
        self.result = .success(result)
    }

    func loadFriends(completion: @escaping (Result<[Friend], Error>) -> Void) {
        loadFriendsCallCount += 1
        completion(result)
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

        let cell1 = sut.tableView.dataSource?.tableView(
            sut.tableView,
            cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(cell1?.textLabel?.text, friend1.name)
        XCTAssertEqual(cell1?.detailTextLabel?.text, friend1.phone)

        let cell2 = sut.tableView.dataSource?.tableView(
            sut.tableView,
            cellForRowAt: IndexPath(row: 1, section: 0))
        XCTAssertEqual(cell2?.textLabel?.text, friend2.name)
        XCTAssertEqual(cell2?.detailTextLabel?.text, friend2.phone)
    }
}

private extension FriendsViewController {
    func simulateViewWillAppear() {
        loadViewIfNeeded()
        beginAppearanceTransition(true, animated: false)
    }

    func numberOfFriends() -> Int {
        tableView.numberOfRows(inSection: 0)
    }
}
