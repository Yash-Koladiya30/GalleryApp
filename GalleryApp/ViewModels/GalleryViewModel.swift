//
//  GalleryViewModel.swift
//  GalleryApp
//
//  Created by Yash Koladiya on 07/03/26.
//

import Foundation
import Network
import SDWebImage

class GalleryViewModel {
    
    var photos: [Photo] = []
    var savedPhotos: [SavedPhoto] = []
    var currentPage = 1
    var isLoading = false
    
    var reloadData: (() -> Void)?
    var showError: ((String) -> Void)?
    var onLoadingStatusChanged: ((Bool) -> Void)?
    
    private let monitor = NWPathMonitor()
    var isOffline = false
    
    init() {
        startNetworkMonitoring()
    }
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let currentlyOffline = path.status != .satisfied
            if self?.isOffline != currentlyOffline {
                self?.isOffline = currentlyOffline
                DispatchQueue.main.async {
                    self?.fetchData()
                }
            }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }
    
    func fetchData() {
        currentPage = 1
        photos.removeAll()
        savedPhotos.removeAll()
        reloadData?()
        
        if isOffline {
            loadOfflineData()
        } else {
            fetchOnlineData()
        }
    }
    
    func fetchOnlineData() {
        guard !isLoading else { return }
        isLoading = true
        onLoadingStatusChanged?(true)
        
        APIManager.shared.fetchPhotos(page: currentPage) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            DispatchQueue.main.async {
                self.onLoadingStatusChanged?(false)
            }
            
            switch result {
            case .success(let newPhotos):
                if self.currentPage == 1 {
                    self.photos = newPhotos
                } else {
                    self.photos.append(contentsOf: newPhotos)
                }
                
                self.prefetchAndSaveImages(for: newPhotos)
                
                DispatchQueue.main.async {
                    self.reloadData?()
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.showError?(error.localizedDescription)
                }
            }
        }
    }
    
    func loadNextPage() {
        guard !isLoading else { return }
        currentPage += 1
        if isOffline {
            loadOfflineData()
        } else {
            fetchOnlineData()
        }
    }
    
    func loadOfflineData() {
        guard !isLoading else { return }
        isLoading = true
        onLoadingStatusChanged?(true)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let newPhotos = CoreDataManager.shared.fetchSavedPhotos(page: self.currentPage, limit: 20)
            
            self.isLoading = false
            self.onLoadingStatusChanged?(false)
            
            if newPhotos.isEmpty && self.currentPage > 1 {
                self.currentPage -= 1
            } else {
                if self.currentPage == 1 {
                    self.savedPhotos = newPhotos
                } else {
                    self.savedPhotos.append(contentsOf: newPhotos)
                }
                self.reloadData?()
            }
        }
    }
    
    func getPhotosCount() -> Int {
        return isOffline ? savedPhotos.count : photos.count
    }
    
    private func prefetchAndSaveImages(for newPhotos: [Photo]) {
        for photo in newPhotos {
            guard let url = URL(string: photo.download_url) else { continue }
            
            SDWebImageManager.shared.loadImage(with: url, options: [.continueInBackground, .lowPriority], progress: nil) { image, data, error, cacheType, finished, imageURL in
                if let image = image, finished {
                    let finalData = data ?? image.jpegData(compressionQuality: 0.8)
                    if let validData = finalData {
                        CoreDataManager.shared.savePhoto(id: photo.id, author: photo.author, data: validData)
                    }
                }
            }
        }
    }
}
