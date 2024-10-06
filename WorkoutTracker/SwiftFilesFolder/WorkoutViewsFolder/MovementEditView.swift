import SwiftUI
import CoreData

struct MovementEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var movement: Movement
    
    @State private var name: String
    @State private var movementClass: String
    @State private var description: String
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    let movementClasses = ["Strength", "Cardio", "Stretch"]
    
    init(movement: Movement) {
        self.movement = movement
        _name = State(initialValue: movement.name ?? "")
        _movementClass = State(initialValue: movement.movementClass ?? "Strength")
        _description = State(initialValue: movement.movementDescription ?? "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Movement Details")) {
                TextField("Movement Name", text: $name)
                
                Picker("Movement Class", selection: $movementClass) {
                    ForEach(movementClasses, id: \.self) { className in
                        Text(className).tag(className)
                    }
                }
                
                TextEditor(text: $description)
                    .frame(height: 100)
            }
            
            Section(header: Text("Movement Photo")) {
                if let imageData = movement.movementPhoto, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
                
                Button("Select Photo") {
                    showingImagePicker = true
                }
            }
            
            Section {
                Button("Save Changes") {
                    saveChanges()
                }
                
                Button("Delete Movement") {
                    deleteMovement()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Edit Movement")
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: $inputImage)
        }
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        movement.movementPhoto = inputImage.jpegData(compressionQuality: 0.8)
    }
    
    private func saveChanges() {
        movement.name = name
        movement.movementClass = movementClass
        movement.movementDescription = description
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
    
    private func deleteMovement() {
        viewContext.delete(movement)
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to delete movement: \(error)")
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
