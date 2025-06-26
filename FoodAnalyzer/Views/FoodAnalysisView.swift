import SwiftUI

struct EnhancedFoodAnalysisView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var foodAnalysisViewModel: FoodAnalysisViewModel
    @State private var animateElements = false
    
    var body: some View {
        ZStack {
            // Background
            Color.theme.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: .spacing.xl) {
                    // Header
                    headerSection
                    
                    // Image Selection/Display
                    imageSection
                    
                    // Analysis Controls
                    analysisControls
                    
                    // Analysis Progress
                    if foodAnalysisViewModel.isAnalyzing {
                        analysisProgressSection
                    }
                    
                    // Results
                    if let result = foodAnalysisViewModel.analysisResult {
                        NutritionCard(
                            analysis: result,
                            onEdit: { analysis in
                                foodAnalysisViewModel.editAnalysis(analysis)
                            },
                            onShare: { analysis in
                                foodAnalysisViewModel.shareAnalysis(analysis)
                            }
                        )
                        .containerPadding()
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    }
                    
                    // Quick Tips
                    if foodAnalysisViewModel.selectedImage == nil && foodAnalysisViewModel.analysisResult == nil {
                        quickTipsSection
                    }
                    
                    Spacer(minLength: .spacing.xxxl)
                }
            }
        }
        .sheet(isPresented: $foodAnalysisViewModel.showImagePicker) {
            ImagePicker(
                sourceType: foodAnalysisViewModel.imagePickerSource,
                selectedImage: $foodAnalysisViewModel.selectedImage
            )
        }
        .overlay(
            // Error Toast
            errorToast,
            alignment: .top
        )
        .onAppear {
            startAnimations()
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: foodAnalysisViewModel.selectedImage)
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: foodAnalysisViewModel.analysisResult)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: .spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: .spacing.xs) {
                    Text("Hello, \(authViewModel.currentUser?.firstName ?? "User")!")
                        .titleLarge()
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 20)
                    
                    Text("What are you eating today?")
                        .bodyLarge(Color.theme.textSecondary)
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 20)
                }
                
                Spacer()
                
                // Profile Button
                Button(action: {}) {
                    AsyncImage(url: URL(string: authViewModel.currentUser?.profileImageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.theme.primary.opacity(0.1))
                            .overlay(
                                Text(authViewModel.currentUser?.initials ?? "")
                                    .labelMedium(Color.theme.primary)
                            )
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .opacity(animateElements ? 1.0 : 0.0)
                    .scaleEffect(animateElements ? 1.0 : 0.8)
                }
            }
            .containerPadding()
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateElements)
    }
    
    // MARK: - Image Section
    private var imageSection: some View {
        VStack(spacing: .spacing.lg) {
            if let image = foodAnalysisViewModel.selectedImage {
                // Selected Image Display
                selectedImageView(image)
            } else {
                // Image Selection Placeholder
                imageSelectionPlaceholder
            }
        }
        .containerPadding()
    }
    
    private func selectedImageView(_ image: UIImage) -> some View {
        VStack(spacing: .spacing.md) {
            // Image Display
            ZStack {
                RoundedRectangle(cornerRadius: .spacing.cornerRadiusLarge)
                    .fill(Color.theme.surface)
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: .spacing.cornerRadiusLarge))
                    .overlay(
                        // Analysis Overlay
                        analysisOverlay,
                        alignment: .topTrailing
                    )
            }
            
            // Image Actions
            HStack(spacing: .spacing.md) {
                Button(action: foodAnalysisViewModel.clearSelection) {
                    HStack(spacing: .spacing.xs) {
                        Image(systemName: "trash")
                        Text("Remove")
                    }
                    .labelMediumStyle(Color.theme.error)
                }
                
                Spacer()
                
                Button(action: { foodAnalysisViewModel.showImagePicker = true }) {
                    HStack(spacing: .spacing.xs) {
                        Image(systemName: "photo")
                        Text("Change")
                    }
                    .labelMediumStyle(Color.theme.primary)
                }
            }
        }
    }
    
    private var imageSelectionPlaceholder: some View {
        VStack(spacing: .spacing.lg) {
            // Placeholder Card
            ZStack {
                RoundedRectangle(cornerRadius: .spacing.cornerRadiusLarge)
                    .fill(Color.theme.surface)
                    .frame(height: 200)
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: 15,
                        x: 0,
                        y: 5
                    )
                
                VStack(spacing: .spacing.md) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color.theme.primary.opacity(0.6))
                    
                    Text("Take a photo or select from library")
                        .bodyLarge(Color.theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .scaleEffect(animateElements ? 1.0 : 0.9)
                .opacity(animateElements ? 1.0 : 0.0)
            }
            
            // Selection Buttons
            HStack(spacing: .spacing.md) {
                PrimaryButton(
                    "Camera",
                    style: .primary
                ) {
                    foodAnalysisViewModel.selectImageFromCamera()
                }
                
                PrimaryButton(
                    "Photo Library",
                    style: .secondary
                ) {
                    foodAnalysisViewModel.selectImageFromLibrary()
                }
            }
            .opacity(animateElements ? 1.0 : 0.0)
            .offset(y: animateElements ? 0 : 30)
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateElements)
    }
    
    // MARK: - Analysis Controls
    private var analysisControls: some View {
        Group {
            if foodAnalysisViewModel.selectedImage != nil && !foodAnalysisViewModel.isAnalyzing {
                PrimaryButton(
                    "Analyze Nutrition",
                    style: .success
                ) {
                    Task {
                        await foodAnalysisViewModel.analyzeSelectedImage()
                    }
                }
                .containerPadding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Analysis Progress
    private var analysisProgressSection: some View {
        VStack(spacing: .spacing.lg) {
            // Progress Card
            VStack(spacing: .spacing.md) {
                // Step Indicator
                HStack(spacing: .spacing.sm) {
                    Image(systemName: foodAnalysisViewModel.analysisStep.icon)
                        .foregroundColor(foodAnalysisViewModel.analysisStep.color)
                        .font(.title2)
                    
                    Text(foodAnalysisViewModel.analysisStep.rawValue)
                        .titleMedium(foodAnalysisViewModel.analysisStep.color)
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.theme.textTertiary.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.theme.primary, Color.theme.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * foodAnalysisViewModel.analysisProgress,
                                height: 8
                            )
                            .animation(.easeInOut(duration: 0.5), value: foodAnalysisViewModel.analysisProgress)
                    }
                }
                .frame(height: 8)
                
                // Progress Text
                Text("\(Int(foodAnalysisViewModel.analysisProgress * 100))%")
                    .labelMedium()
                    .foregroundColor(Color.theme.textSecondary)
            }
            .cardPadding()
            .background(
                RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                    .fill(Color.theme.surface)
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: 10,
                        x: 0,
                        y: 2
                    )
            )
            .containerPadding()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Analysis Overlay
    private var analysisOverlay: some View {
        Group {
            if foodAnalysisViewModel.isAnalyzing {
                ZStack {
                    RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 80, height: 80)
                    
                    VStack(spacing: .spacing.xs) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        
                        Text("Analyzing")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.spacing.md)
            }
        }
    }
    
    // MARK: - Quick Tips
    private var quickTipsSection: some View {
        VStack(spacing: .spacing.lg) {
            Text("💡 Quick Tips")
                .titleMedium()
                .frame(maxWidth: .infinity, alignment: .leading)
                .containerPadding()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: .spacing.md) {
                tipCard("📸", title: "Good Lighting", subtitle: "Take photos in natural light for best results")
                tipCard("🍽️", title: "Full Plate", subtitle: "Show the entire meal for accurate analysis")
                tipCard("📏", title: "Close View", subtitle: "Get close enough to see food details")
                tipCard("🔄", title: "Multiple Angles", subtitle: "Try different angles if first attempt fails")
            }
            .containerPadding()
        }
        .opacity(animateElements ? 1.0 : 0.0)
        .offset(y: animateElements ? 0 : 40)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: animateElements)
    }
    
    private func tipCard(_ emoji: String, title: String, subtitle: String) -> some View {
        VStack(spacing: .spacing.sm) {
            Text(emoji)
                .font(.title)
            
            Text(title)
                .labelMedium()
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .cardPadding()
        .background(
            RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                .fill(Color.theme.surface)
                .shadow(
                    color: Color.black.opacity(0.03),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
    }
    
    // MARK: - Error Toast
    private var errorToast: some View {
        Group {
            if foodAnalysisViewModel.showError, let errorMessage = foodAnalysisViewModel.errorMessage {
                VStack {
                    HStack(spacing: .spacing.sm) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.white)
                        
                        Text(errorMessage)
                            .bodyMedium(.white)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Button(action: foodAnalysisViewModel.clearError) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.caption)
                        }
                    }
                    .cardPadding()
                    .background(
                        RoundedRectangle(cornerRadius: .spacing.cornerRadius)
                            .fill(Color.theme.error)
                            .shadow(radius: 10)
                    )
                    .containerPadding()
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: foodAnalysisViewModel.showError)
    }
    
    // MARK: - Helper Methods
    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
            animateElements = true
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    EnhancedFoodAnalysisView()
        .environmentObject(AuthViewModel())
        .environmentObject(FoodAnalysisViewModel())
}