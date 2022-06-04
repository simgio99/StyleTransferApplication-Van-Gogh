//
//  ContentView.swift
//  Becasso_NC2
//
//  Created by Simone Giordano on 09/12/21.
//

import SwiftUI
import PhotosUI
import CoreImage
import CoreGraphics

extension UIImage {
    func clone() -> UIImage? {
        guard let originalCgImage = self.cgImage, let newCgImage = originalCgImage.copy() else {
            return nil
        }
        
        return UIImage(cgImage: newCgImage, scale: self.scale, orientation: self.imageOrientation)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    self.parent.image = image as? UIImage
                }
            }
        }
    }
}




struct ImageEditorView: View {
    var inputImage: Binding<UIImage?>
    @State var slider_val = 0.5
    var rect: CGRect!
    var renderer: UIGraphicsImageRenderer!
    @State var renderedImage: UIImage!
    @Environment(\.presentationMode) var presentationMode
    
    var blendModes: [CGBlendMode] = [.normal, .color, .multiply, .colorBurn, .darken, .hardLight, .luminosity, .overlay, .saturation, .softLight, .hue]
    let blendModesDictionary = [ CGBlendMode.normal : "Normal",
                                 CGBlendMode.color: "Color",
                                 CGBlendMode.softLight : "Soft Light",
                                 CGBlendMode.saturation : "Saturation",
                                 CGBlendMode.luminosity : "Luminosity",
                                 CGBlendMode.multiply : "Multiply",
                                 CGBlendMode.overlay : "Overlay",
                                 CGBlendMode.hue : "Hue",
                                 CGBlendMode.hardLight : "Hard Light",
                                 CGBlendMode.darken : "Darken",
                                 CGBlendMode.colorBurn : "Color Burn"
    ]
    @State var selectedBlendMode: CGBlendMode = .normal
    var predictedImage: UIImage {
        var tempImage = predict(raw_image: inputImage.wrappedValue!)
        //tempImage = tempImage.resizeImageTo(size: inputImage.wrappedValue!.size)!
        return tempImage
    }
    
    
    
    init(image: Binding<UIImage?>) {
        self.inputImage = image
        _renderedImage = State(wrappedValue: image.wrappedValue)
        
        rect = CGRect(x: 0, y: 0, width: inputImage.wrappedValue!.size.width, height: inputImage.wrappedValue!.size.height)
        renderer = UIGraphicsImageRenderer(size: inputImage.wrappedValue!.size, format: UIGraphicsImageRendererFormat(for: .current))
        
        
        //Use this if NavigationBarTitle is with Large Font
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        //Use this if NavigationBarTitle is with displayMode = .inline
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        
        
    }
    
    
    var body: some View {
        NavigationView {
            
            
            VStack {
                
                Image(uiImage: renderedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.width, height:UIScreen.main.bounds.height - 300)
                
                Spacer()
                Rectangle()
                    .frame(width: 1000, height: 3)
                    .foregroundColor(.white)
                    .opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    ScrollView(.horizontal) {
                        HStack(spacing: 60) {
                            Spacer()
                            ForEach(blendModes, id: \.self) { bm in
                                Text(self.blendModesDictionary[bm] ?? "?")
                                    .fontWeight(selectedBlendMode == bm ? .bold : .regular)
                                    .onTapGesture {
                                        selectedBlendMode = bm
                                    }
                                    
                            }
                            Spacer()
                        }.foregroundColor(.white)
                            .font(.headline)
                            .frame(height:40)
                        
                        
                    }
                    Slider(value: $slider_val) {
                        editing in
                        if(editing == false) {
                            let result = renderer.image { ctx in
                                // fill the background with white so that translucent colors get lighter
                                UIColor.white.set()
                                ctx.fill(rect)
                                
                                predictedImage.draw(in: rect, blendMode: .normal, alpha: 1)
                                inputImage.wrappedValue!.draw(in: rect, blendMode: selectedBlendMode, alpha: 1 - slider_val)
                                
                            }
                            renderedImage = result
                        }
                    }
                    .accentColor(.white)
                    .onSubmit {
                        
                        
                        
                    }
                    .frame(height: 50)
                }.background(.black)
                
            }
            .background(.black)
            .navigationTitle("Edit your picture")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .cancel) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
            }
            
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        UIImageWriteToSavedPhotosAlbum(renderedImage, nil, nil, nil)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
            }
            
        }
    }
}

struct ContentView: View {
    @State private var showingImagePicker = false
    @State private var showingImageEditor = false
    @State private var inputImage: UIImage? = UIImage(named: "placeholder")
    
    init() {
            //Use this if NavigationBarTitle is with Large Font
            UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]

            //Use this if NavigationBarTitle is with displayMode = .inline
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.7)
                
                
                VStack {
                    Spacer()
                    Button() {
                        showingImagePicker = true
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(.white)
                                .frame(width: 350, height: 50)
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundColor(.black)
                                Text("Choose Picture from Library")
                                    .foregroundColor(.black)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                            }
                            
                        }
                    }
                    Spacer()
                }
                .onChange(of: inputImage) { _ in loadImage()
                    showingImageEditor = true
                }
                .navigationTitle("Becasso")
                
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(image: $inputImage)
                }
                .fullScreenCover(isPresented: $showingImageEditor) {
                    ImageEditorView(image: self.$inputImage)
                }
            }
            
        }
    }
    func loadImage() {
        guard let inputImage = inputImage else { return }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
