//
//  MenuController.swift
//  MyUBER
//
//  Created by admin on 29.06.2022.
//

import UIKit

private let reuseIdentifier = "MenuCell"

 enum MenuOptions: Int, CaseIterable, CustomStringConvertible {
    case yourTrips
    case settings
    case logout

    var description: String {
        switch self {
        case .yourTrips: return "Your Trips"
        case .settings: return "Settings"
        case .logout: return "Log Out"
        }
    }
}

protocol MenuControllerDelegate: class {
    func didSelect(option: MenuOptions)
}

class MenuController: UIViewController {

    //MARK: - Properties

    private let user: User
    weak var delegate: MenuControllerDelegate?

    private var tableView = UITableView()

    private lazy var menuHeader: MenuHeader = {
        let frame = CGRect(x: 0,
                           y: 0,
                           width: self.view.frame.width - 80,
                           height: 140)
        let view = MenuHeader(user: user, frame: frame)
        return view
    }()


    //MARK: - Lifecycle

    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }

    //MARK: - Selectors

    //MARK: - Helpers

    func configureTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = view.frame
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = 60
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.tableHeaderView = menuHeader
    }
}

//MARK: - TableViewDataSource, TableViewDelegate

extension MenuController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuOptions.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        guard let option = MenuOptions(rawValue: indexPath.row) else { return UITableViewCell()}
        cell.textLabel?.text = option.description

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let option = MenuOptions(rawValue: indexPath.row) else { return }
        delegate?.didSelect(option: option)
    }
}


