//
//  UserInfoHeader.swift
//  MyUBER
//
//  Created by admin on 30.06.2022.
//

import UIKit

class UserInfoHeader: UIView {

    //MARK: - Properties

    private let user: User

    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .lightGray
        return iv
    }()

    private lazy var fullnameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = "Test Fullname"
        label.text = user.fullname
        return label
    }()

    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.text = "Test email"
        label.text = user.email
        return label
    }()

    //MARK: - Lifecycle

    init(user: User, frame: CGRect) {
        self.user = user
        super.init(frame: frame)

        backgroundColor = .white

        addSubview(profileImageView)
        profileImageView.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 16)
        profileImageView.layer.cornerRadius = 64 / 2
        profileImageView.setDimensions(height: 64, width: 64)

        let stack = UIStackView(arrangedSubviews: [fullnameLabel, emailLabel])
        stack.distribution = .fillEqually
        stack.spacing = 4
        stack.axis = .vertical

        addSubview(stack)
        stack.centerY(inView: profileImageView, leftAnchor: profileImageView.rightAnchor, paddingLeft: 12)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    //MARK: - Helpers
}
