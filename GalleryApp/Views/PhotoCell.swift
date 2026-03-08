//
//  PhotoCell.swift
//  GalleryApp
//
//  Created by Yash Koladiya on 07/03/26.
//

import UIKit
import SDWebImage
import CoreData

class PhotoCell: UICollectionViewCell {
    
    // MARK: - Outlets
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    // MARK: - Properties
    private var currentPhotoId: String?
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        photoImageView.layer.cornerRadius = 8
        photoImageView.clipsToBounds = true
        photoImageView.contentMode = .scaleAspectFill
        
        // Loader
        photoImageView.sd_imageIndicator = SDWebImageActivityIndicator.medium
    }
    
    // MARK: - Configuration
    func configureOnline(with photo: Photo) {
        titleLabel.text = photo.author
        currentPhotoId = photo.id
        
        if let url = URL(string: photo.download_url) {
            photoImageView.sd_setImage(with: url)
        }
    }
    
    func configureOffline(with photo: SavedPhoto) {
        titleLabel.text = photo.author
        currentPhotoId = photo.id
        
        guard let expectedId = photo.id else { return }
        
        // Fast-path: Check memory cache to completely prevent blinking
        if let cachedImage = SDImageCache.shared.imageFromMemoryCache(forKey: expectedId) {
            photoImageView.image = cachedImage
            return
        }
        
        let objectID = photo.objectID
        
        CoreDataManager.shared.persistentContainer.performBackgroundTask { bgContext in
            if let bgPhoto = try? bgContext.existingObject(with: objectID) as? SavedPhoto,
               let data = bgPhoto.imageData,
               let image = UIImage(data: data) {
                
                // Store in rapid-access memory cache for zero-blink re-scrolling
                SDImageCache.shared.store(image, imageData: nil, forKey: expectedId, toDisk: false)
                
                DispatchQueue.main.async {
                    if self.currentPhotoId == expectedId {
                        self.photoImageView.image = image
                    }
                }
            }
        }
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = nil
        titleLabel.text = nil
    }
}
