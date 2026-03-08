//
//  ProfileViewModel.swift
//  GalleryApp
//
//  Created by Yash Koladiya on 07/03/26.
//

import Foundation
import GoogleSignIn
import UIKit

class ProfileViewModel {
    
    // MARK: - Callbacks
    var onAuthStateChanged: (() -> Void)?
    var onError: ((String) -> Void)?
    
    // MARK: - Properties
    var isLoggedIn: Bool {
        return GIDSignIn.sharedInstance.currentUser != nil
    }
    
    // MARK: - Profile Details
    func getUserEmail() -> String {
        return GIDSignIn.sharedInstance.currentUser?.profile?.email ?? "No Email found"
    }
    
    func getUserName() -> String {
        return GIDSignIn.sharedInstance.currentUser?.profile?.name ?? "User"
    }
    
    func getProfileImageURL() -> URL? {
        // SDWebImage will gracefully handle a nil url
        guard let user = GIDSignIn.sharedInstance.currentUser else { return nil }
        let dimension = round(100 * UIScreen.main.scale)
        guard user.profile?.hasImage == true else { return nil }
        return user.profile?.imageURL(withDimension: UInt(dimension))
    }
    
    // MARK: - Authentication Methods
    func googleSignIn(presenting viewController: UIViewController) {
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { [weak self] signInResult, error in
            if let error = error {
                let nsError = error as NSError
                if nsError.code != GIDSignInError.canceled.rawValue {
                    self?.onError?(error.localizedDescription)
                }
                return
            }
            
            self?.onAuthStateChanged?()
        }
    }
    
    func logout() {
        GIDSignIn.sharedInstance.signOut()
        self.onAuthStateChanged?()
    }
}
