//
//  GalleryViewController.swift
//  GalleryApp
//
//  Created by Yash Koladiya on 07/03/26.
//

import UIKit
import SDWebImage
import GoogleSignIn

class GalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // MARK: - Outlets & Properties
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    // Configurable column count state
    var columns: CGFloat = 3 {
        didSet {
            if columns != oldValue {
                collectionView.performBatchUpdates(nil, completion: nil)
            }
        }
    }
    
    private var pinchStartColumns: CGFloat = 0
    
    var viewModel = GalleryViewModel()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let isLoggedIn = GIDSignIn.sharedInstance.currentUser != nil
        
        if !isLoggedIn {
            viewModel.photos.removeAll()
            viewModel.savedPhotos.removeAll()
            collectionView.reloadData()
            
            let alert = UIAlertController(title: "Authentication Required", message: "Please sign in from the Profile tab to securely view and sync your gallery.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Go to Profile", style: .default, handler: { [weak self] _ in
                self?.tabBarController?.selectedIndex = 1
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        } else {
            if viewModel.photos.isEmpty && viewModel.savedPhotos.isEmpty {
                viewModel.fetchData()
            }
        }
    }
    
    // MARK: - Private Methods
    func setupUI() {
        title = "Gallery"
        view.backgroundColor = .systemBackground
        
        collectionView.register(UINib(nibName: "PhotoCell", bundle: nil), forCellWithReuseIdentifier: "PhotoCell")
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = 2
            layout.minimumInteritemSpacing = 2
            layout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        }
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        collectionView.addGestureRecognizer(pinch)
        
        navigationItem.rightBarButtonItem = nil
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began {
            pinchStartColumns = columns
        } else if gesture.state == .changed {
            let scale = gesture.scale
            guard scale > 0 else { return }
            
            // Scale > 1 mean zoom in
            // scle < 1 means zoom out
            let newColumns = pinchStartColumns / scale
            let clamped = max(1, min(newColumns, 7))
            
            let rounded = round(clamped)
            if rounded != columns {
                columns = rounded
            }
        }
    }
    
    func setupViewModel() {
        viewModel.reloadData = { [weak self] in
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
            }
        }
        
        viewModel.showError = { [weak self] errorMessage in
            let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
        
        viewModel.onLoadingStatusChanged = { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
        }
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getPhotosCount()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        if viewModel.isOffline {
            let savedPhoto = viewModel.savedPhotos[indexPath.item]
            cell.configureOffline(with: savedPhoto)
            
            // Offline Pagination
            if indexPath.item == viewModel.savedPhotos.count - 1 {
                viewModel.loadNextPage()
            }
        } else {
            let photo = viewModel.photos[indexPath.item]
            cell.configureOnline(with: photo)
            
            // Online Pagination
            if indexPath.item == viewModel.photos.count - 1 {
                viewModel.loadNextPage()
            }
        }
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 2.0
        let totalSpacing = spacing * (columns + 1)
        
        let width = floor((collectionView.bounds.width - totalSpacing) / columns)
        
        return CGSize(width: width, height: width)
    }
}
