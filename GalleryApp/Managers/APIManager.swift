//
//  APIManager.swift
//  GalleryApp
//
//  Created by Yash Koladiya on 07/03/26.
//

import Foundation

class APIManager {
    // MARK: - Singleton
    static let shared = APIManager()
    private init() {}
    
    // MARK: - Network Request
    func fetchPhotos(page: Int, limit: Int = 20, completion: @escaping (Result<[Photo], Error>) -> Void) {
        let urlString = "https://picsum.photos/v2/list?page=\(page)&limit=\(limit)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let photos = try JSONDecoder().decode([Photo].self, from: data)
                completion(.success(photos))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
