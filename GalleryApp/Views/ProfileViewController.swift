//
//  ProfileViewController.swift
//  GalleryApp
//
//  Created by Yash Koladiya on 07/03/26.
//

import UIKit
import SDWebImage

class ProfileViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    
    // MARK: - Properties
    var viewModel = ProfileViewModel()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupViewModel()
        updateViewState()
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        title = "Profile"
        view.backgroundColor = .systemBackground
        
        logoutButton.layer.cornerRadius = 8
        logoutButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
    }
    
    private func setupViewModel() {
        viewModel.onAuthStateChanged = { [weak self] in
            DispatchQueue.main.async {
                self?.updateViewState()
            }
        }
        
        viewModel.onError = { [weak self] errorMessage in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Sign In Error", message: errorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }
    
    private func updateViewState() {
        let isLoggedIn = viewModel.isLoggedIn
        
        if isLoggedIn {
            nameLabel.text = viewModel.getUserName()
            nameLabel.textColor = .label
            
            emailLabel.text = viewModel.getUserEmail()
            emailLabel.isHidden = false
            
            logoutButton.backgroundColor = .systemRed
            logoutButton.setTitleColor(.white, for: .normal)
            logoutButton.setTitle("Logout", for: .normal)
        } else {
            nameLabel.text = "Sign in to manage profile."
            nameLabel.textColor = .secondaryLabel
            
            emailLabel.isHidden = true
            
            logoutButton.backgroundColor = .systemBlue
            logoutButton.setTitleColor(.white, for: .normal)
            logoutButton.setTitle("Continue with Google", for: .normal)
        }
    }
    
    // MARK: - Actions
    @IBAction func logoutButtonTapped(_ sender: Any) {
        if viewModel.isLoggedIn {
            viewModel.logout()
        } else {
            viewModel.googleSignIn(presenting: self)
        }
    }
}
