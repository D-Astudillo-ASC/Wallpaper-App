//
//  Model.swift
//  WallpaperApp
//
//  Created by Daniel Astudillo on 1/3/22.
//

import Foundation
struct Photo: Identifiable, Decodable {
    var id: String
    var description: String?
    var alt_description: String?
    var urls: [String: String]
}

class UnsplashData: ObservableObject {
    @Published var photoArr: [Photo] = []
    
    private var apiKey: String {
      get {
        // 1 - file not found.
        guard let filePath = Bundle.main.path(forResource: "Unsplashed-Info", ofType: "plist") else {
          fatalError("Couldn't find file 'Unsplashed-Info.plist'.")
        }
        // 2 - key not found.
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "API_KEY") as? String else {
          fatalError("Couldn't find key 'API_KEY' in 'Unsplashed-Info.plist'.")
        }
        return value
      }
    }
    
    init(){
        loadData()
    }
    
    func loadData(){
        let url = "https://api.unsplash.com/photos/random/?count=5&client_id=\(apiKey)"
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: URL(string: url)!) {(data, _, error) in guard let data = data else{
                print("URLSession dataTask error: \(error!)")
                return
            }
            do{
//                print(String(data: data, encoding: .utf8)!)
                let json = try JSONDecoder().decode([Photo].self, from: data)
//                print("json: \(json)")
                for photo in json{
                    DispatchQueue.main.async {
                        self.photoArr.append(photo)
                    }
                }
            }
            catch let error{
                print(String(describing: error))
            }
            
        }
        task.resume()
    }
    
    func refresh(){
        photoArr = []
        loadData()
    }
}

