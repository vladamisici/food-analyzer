import SwiftUI
import PhotosUI

struct EnhancedFoodAnalysisView: View {
    @EnvironmentObject var viewModel: FoodAnalysisViewModel
    @EnvironmentObject var goalsViewModel: GoalsViewModel
    @State private var showSuccessAnimation = false
    @State private var showErrorAnimation = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var animateCamera = false
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                        .slideIn(delay: 0.1)
                    
                    imagePickerSection
                        .scaleIn(delay: 0.2)
                    
                    if viewModel.selectedImage != nil && !viewModel.isAnalyzing {
                        analyzeButton
                            .fadeIn(delay: 0.3)
                    }
                    
                    if viewModel.isAnalyzing {
                        AnimatedLoadingView(message: "Analyzing your food...")
                            .transition(.scaleAndFade)
                    }
                    
                    if let result = viewModel.analysisResult {
                        resultSection(result)
                            .transition(.bottomSlide)
                    }
                }
                .padding()
            }
            
            if showSuccessAnimation {
                SuccessAnimationView {
                    withAnimation {
                        showSuccessAnimation = false
                    }
                }
                .zIndex(1)
            }
            
            if showErrorAnimation {
                ErrorAnimationView(message: viewModel.errorMessage ?? "Something went wrong") {
                    withAnimation {
                        showErrorAnimation = false
                        viewModel.errorMessage = nil
                    }
                }
                .zIndex(1)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            // Folosește UIImagePickerController direct prin UIViewControllerRepresentable
            CameraPickerView(image: $viewModel.selectedImage, sourceType: sourceType)
        }
        .onChange(of: viewModel.analysisResult) { newValue in
            if newValue != nil {
                showSuccessAnimation = true
                HapticManager.shared.analysisComplete()
            }
        }
        .onChange(of: viewModel.showError) { showError in
            if showError {
                showErrorAnimation = true
                viewModel.showError = false
                HapticManager.shared.error()
            }
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.selectedImage = image
                    HapticManager.shared.selection()
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Food Analysis")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Take a photo to get instant nutrition insights")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var imagePickerSection: some View {
        VStack(spacing: 16) {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
                    .parallax(magnitude: 0.05)
                
                HStack(spacing: 16) {
                    PhotosPicker(selection: $selectedPhotoItem,
                                matching: .images,
                                photoLibrary: .shared()) {
                        Label("Change Photo", systemImage: "photo.on.rectangle")
                            .font(.subheadline)
                            .foregroundColor(.theme.primary)
                    }
                    
                    Button(action: {
                        sourceType = .camera
                        showImagePicker = true
                    }) {
                        Label("Retake", systemImage: "camera.fill")
                            .font(.subheadline)
                            .foregroundColor(.theme.primary)
                    }
                }
                .padding(.top, 8)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.theme.surface)
                        .frame(height: 250)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                                .foregroundColor(.theme.primary.opacity(0.3))
                        )
                    
                    VStack(spacing: 20) {
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.theme.primary)
                            .rotationEffect(.degrees(animateCamera ? 10 : -10))
                            .animation(
                                Animation.easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true),
                                value: animateCamera
                            )
                        
                        Text("Tap to add a photo")
                            .font(.headline)
                            .foregroundColor(.theme.textSecondary)
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                sourceType = .camera
                                showImagePicker = true
                                HapticManager.shared.lightTap()
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.title2)
                                    Text("Camera")
                                        .font(.caption)
                                }
                                .foregroundColor(.theme.primary)
                                .frame(width: 80, height: 80)
                                .background(Color.theme.primary.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .bounce(trigger: showImagePicker)
                            
                            PhotosPicker(selection: $selectedPhotoItem,
                                        matching: .images,
                                        photoLibrary: .shared()) {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.fill")
                                        .font(.title2)
                                    Text("Gallery")
                                        .font(.caption)
                                }
                                .foregroundColor(.theme.primary)
                                .frame(width: 80, height: 80)
                                .background(Color.theme.primary.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .onTapGesture {
                    sourceType = .camera
                    showImagePicker = true
                    HapticManager.shared.lightTap()
                }
                .onAppear {
                    animateCamera = true
                }
            }
        }
    }
    
    private var analyzeButton: some View {
        Button(action: {
            Task {
                if let image = viewModel.selectedImage {
                    await viewModel.analyzeFood(image: image)
                    HapticManager.shared.mediumTap()
                }
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                Text("Analyze Food")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.theme.primary, Color.theme.accent]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .pulsating(isActive: true)
        .disabled(viewModel.isAnalyzing)
    }
    
    private func resultSection(_ result: FoodAnalysisResponse) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Food name and basic info
            VStack(alignment: .leading, spacing: 8) {
                Text(result.itemName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .slideIn()
                
                HStack(spacing: 16) {
                    Label("\(result.healthScoreValue)/10", systemImage: "heart.fill")
                        .font(.subheadline)
                        .foregroundColor(healthScoreColor(result.healthScoreValue))
                    
                    Label("\(result.calories) cal", systemImage: "flame.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                .fadeIn(delay: 0.2)
            }
            
            // Nutrition grid using the analysis data
            AnimatedNutritionGrid(
                calories: Double(result.calories),
                protein: result.proteinValue,
                carbs: result.carbsValue,
                fat: result.fatValue,
                goals: goalsViewModel.currentGoals
            )
            
            // Coach comments
            if !result.coachComment.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("AI Insights", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundColor(.theme.primary)
                    
                    Text(result.coachComment)
                        .font(.body)
                        .foregroundColor(.theme.textSecondary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.theme.primary.opacity(0.1))
                        )
                }
                .slideIn(delay: 0.3)
            }
            
            // Nutrition insights
            if !result.insights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Nutrition Insights", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundColor(.theme.accent)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(result.insights, id: \.id) { insight in
                            HStack(spacing: 12) {
                                Image(systemName: insightIcon(for: insight.type))
                                    .foregroundColor(insightColor(for: insight.severity))
                                    .font(.title3)
                                
                                Text(insight.message)
                                    .font(.body)
                                    .foregroundColor(.theme.textSecondary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(insightColor(for: insight.severity).opacity(0.1))
                            )
                        }
                    }
                }
                .slideIn(delay: 0.4)
            }
            
            // Action buttons
            HStack(spacing: 16) {
                Button(action: {
                    // Simple save action - just show success for now
                    HapticManager.shared.save()
                    // TODO: Implement save functionality based on your ViewModel methods
                }) {
                    Label("Save", systemImage: "bookmark.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.theme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    viewModel.selectedImage = nil
                    viewModel.analysisResult = nil
                    HapticManager.shared.lightTap()
                }) {
                    Label("New Analysis", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.theme.surface)
                        .foregroundColor(.theme.primary)
                        .cornerRadius(12)
                }
            }
            .fadeIn(delay: 0.5)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.theme.surface)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }
    
    // MARK: - Helper Functions
    
    private func healthScoreColor(_ score: Int) -> Color {
        switch score {
        case 8...10: return .green
        case 5...7: return .orange
        default: return .red
        }
    }
    
    private func insightIcon(for type: FoodAnalysisResponse.NutritionInsight.InsightType) -> String {
        switch type {
        case .highSodium:
            return "exclamationmark.triangle"
        case .lowProtein:
            return "info.circle"
        case .goodProtein:
            return "bolt.circle.fill"
        case .highFat:
            return "exclamationmark.triangle"
        case .highCalorie:
            return "flame.circle"
        case .highSugar:
            return "exclamationmark.triangle"
        case .goodFiber:
            return "checkmark.circle"
        case .balanced:
            return "checkmark.circle"
        }
    }
    
    private func insightColor(for severity: FoodAnalysisResponse.NutritionInsight.Severity) -> Color {
        switch severity {
        case .info: return .blue
        case .warning: return .orange
        case .positive: return .green
        }
    }
}

// MARK: - CameraPickerView for UIImagePickerController

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPickerView
        
        init(_ parent: CameraPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    EnhancedFoodAnalysisView()
        .environmentObject(FoodAnalysisViewModel())
        .environmentObject(GoalsViewModel())
}
