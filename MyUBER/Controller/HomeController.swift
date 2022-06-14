//
//  HomeController.swift
//  MyUBER
//
//  Created by admin on 14.06.2022.
//

import UIKit
import Firebase

class HomeController: UIViewController {

    //MARK: - Properties

    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()
    //    signOut()
        view.backgroundColor = .red
    }

    //MARK: - API

    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            let nav = UINavigationController(rootViewController: LoginController())
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        } else {
            print("DEBUG: User id is \(Auth.auth().currentUser?.uid)")
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("DEBUG: Error signing out")
        }
    }
}
