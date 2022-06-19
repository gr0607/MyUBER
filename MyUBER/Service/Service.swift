//
//  Service.swift
//  MyUBER
//
//  Created by admin on 19.06.2022.
//

import Firebase

let DB_REF = Database.database().reference()
let REF_USERS = DB_REF.child("users")

struct Service {

    static let shared = Service()
    let currentUid = Auth.auth().currentUser?.uid


    func fetchUserData(completion: @escaping (String) -> Void) {
        REF_USERS.child(currentUid!).observeSingleEvent(of: .value) { snapshot in
            guard let dictionary = snapshot.value as? [String: Any] else { return }
            guard let fullname = dictionary["fullname"] as? String else { return }
            completion(fullname)
        }
    }
}
