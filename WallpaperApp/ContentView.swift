//
//  ContentView.swift
//  WallpaperApp
//
//  Created by Daniel Astudillo on 1/3/22.
//

import SwiftUI
import SDWebImageSwiftUI

struct ImageView: View{
    var image: Photo
    @Binding var lastHoveredId: String
    @State private var isHovered: Bool = false
    var id: String
    @State var imgPath: URL? = URL(fileURLWithPath: "")
    private func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    private func downloadNew(url: URL) {
        
        //construct path for downloads folder.
        guard let downloadsPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask ).first?.appendingPathComponent("WallpaperApp_Images").path else{ return }
        
        
        //Create downloads folder for app if it doesn't already exist.
        if !FileManager.default.fileExists(atPath: downloadsPath){
            do{
                try FileManager.default.createDirectory(atPath: downloadsPath, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error{
                print(String(describing: error))
            }
        }
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print("Download Finished")
            
            let img = NSImage(data: data)
            let cgImg = img!.cgImage(forProposedRect: nil, context: nil, hints: nil)
            let bitmapRep = NSBitmapImageRep(cgImage: cgImg!)
            let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!
            var imgDownPath = downloadsPath
            imgDownPath += "/desktop-\(id).jpg"
            self.imgPath = URL(fileURLWithPath: imgDownPath)
            do{
                try jpegData.write(to: self.imgPath!)
                let workspace = NSWorkspace.shared
                if let screen = NSScreen.main  {
                    do{
                        let curDesktopImg = workspace.desktopImageURL(for: screen)
                        try FileManager.default.removeItem(at: curDesktopImg!)
                    }
                    catch let deleteError{
                        print("Error deleting previous desktop image: \(String(describing: deleteError))")
                    }
                    do{
                        try workspace.setDesktopImageURL(self.imgPath!,for: screen, options: [:])
                    }
                    catch let setImageError{
                        print("Error setting new image: \(String(describing: setImageError))")
                    }
                }
                
            }
            catch let writeError{
                print("Error writing to jpg: \(String(describing: writeError))")
            }
        }
    }
    var body: some View{
        Button(action: {
            let imgUrl: String? = image.urls["full"] ?? "full img not found"
            if imgUrl != "full img not found"{
                let wallpaper = URL(string: imgUrl!)
                downloadNew(url: wallpaper!)
            }
            
        }){
            if #available(macOS 11.0, *) {
                WebImage(url: URL(string: image.urls["small"] ?? "small size not found")).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 360, height: 200, alignment: .center)
                    .cornerRadius(15)
                    .contentShape(Rectangle())
                    .onChange(of: lastHoveredId) {
                        isHovered = $0 == id
                    }
            } else {
                // Fallback on earlier versions
            }
        }.buttonStyle(PlainButtonStyle())
        
    }
}

struct ContentView: View {
    @StateObject var randomImages = UnsplashData()
    @State private var lastHoveredId = ""
    
    var body: some View {
        if #available(OSX 11.0, *) {
            Text("Wallpaper App").font(.title).frame(alignment: .center).padding(.top, 15)
            ScrollView{
                //                LazyVStack (alignment: .leading, content: {
                
                ForEach(randomImages.photoArr, id: \.id) { photo in
                    ImageView(image: photo,lastHoveredId: $lastHoveredId, id: photo.id, imgPath: URL(fileURLWithPath: "")).onHover { isHovered in
                        if isHovered {
                            NSCursor.pointingHand.push()
                            lastHoveredId = photo.id
                        } else if lastHoveredId == photo.id {
                            NSCursor.pop()
                            lastHoveredId = ""
                        }
                    }
                    Text(photo.description ?? ( photo.alt_description ?? "Photo description not found")).font(.footnote).clipped()
                }
            }.frame(width: 400, height: 400, alignment: .center)
            Button(action:{
                randomImages.refresh()
            }){
                Text("Refresh")
            }.padding(.bottom, 20.0)
        } else {
            // Fallback on earlier versions
            //don't know what to put here yet...
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

