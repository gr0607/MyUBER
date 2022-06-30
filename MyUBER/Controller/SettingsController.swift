//
//  SettingsController.swift
//  MyUBER
//
//  Created by admin on 30.06.2022.
//

import UIKit

private let reuseIdentifier = "LocationCell"

class SettingsController: UITableViewController {

    //MARK: - Properties

    private let user: User

    private lazy var infoHeader: UserInfoHeader = {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 100)
        let view = UserInfoHeader(user: user, frame: frame)

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
        configureNavigationBar()
    }

    //MARK: - Selectors

    @objc func handleDismissal() {
        self.dismiss(animated: true, completion: nil)
    }

    //MARK: - Helpers

    func configureTableView() {
        tableView.rowHeight = 60
        tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.backgroundColor = .white
        tableView.tableHeaderView  = infoHeader
    }

    func configureNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = .black
        navigationItem.title = "Settings"
        navigationController?.navigationBar.barTintColor = .backgroundColor

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "baseline_clear_white_36pt_2x").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleDismissal))
    }
}
