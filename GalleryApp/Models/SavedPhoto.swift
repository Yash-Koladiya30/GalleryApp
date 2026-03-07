//
//  SavedPhoto.swift
//  GalleryApp
//
//  Created by Yash Koladiya on 07/03/26.
//

import Foundation
import CoreData

@objc(SavedPhoto)
public class SavedPhoto: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var author: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var createdAt: Date?
}
