import SwiftUI
import PhotosUI

struct EnhancedFoodAnalysisView: View {
    @EnvironmentObject var viewModel: FoodAnalysisViewModel
    @EnvironmentObject var goalsViewModel: GoalsViewModel
    @State private var showSuccessAnimation = false
    @State private var showErrorAnimation = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var animateCamera = false
    
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
        .onChange(of: viewModel.analysisResult) { newValue in
            if newValue != nil {
                showSuccessAnimation = true
            }
        }
        .onChange(of: viewModel.showError) { showError in
            if showError {
                showErrorAnimation = true
                viewModel.showError = false
            }
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.selectedImage = image
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
                    
                    Button(action: { viewModel.takePhoto }) {
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
                            Button(action: { viewModel.takePhoto() }) {
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
                            .bounce(trigger: viewModel.showImagePicker)
                            
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
                    viewModel.takePhoto()
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
                await viewModel.analyzeFood()
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
    }
    
    private func resultSection(_ result: FoodAnalysisResponse) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(result.foodName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .slideIn()
                
                HStack(spacing: 16) {
                    Label("\(result.healthScore)/10", systemImage: "heart.fill")
                        .font(.subheadline)
                        .foregroundColor(healthScoreColor(result.healthScore))
                    
                    Label("\(Int(result.nutrition.calories)) cal", systemImage: "flame.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                .fadeIn(delay: 0.2)
            }
            
            AnimatedNutritionGrid(
                nutrition: result.nutrition,
                goals: goalsViewModel.nutritionGoals
            )
            
            if !result.coachingComments.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("AI Insights", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundColor(.theme.primary)
                    
                    Text(result.coachingComments)
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
            
            HStack(spacing: 16) {
                Button(action: { viewModel.saveAnalysis() }) {
                    Label("Save", systemImage: "bookmark.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.theme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: { viewModel.resetAnalysis() }) {
                    Label("New Analysis", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.theme.surface)
                        .foregroundColor(.theme.primary)
                        .cornerRadius(12)
                }
            }
            .fadeIn(delay: 0.4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.theme.surface)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }
    
    private func healthScoreColor(_ score: Int) -> Color {
        switch score {
        case 8...10: return .green
        case 5...7: return .orange
        default: return .red
        }
    }
}

#Preview {
    EnhancedFoodAnalysisView()
        .environmentObject(FoodAnalysisViewModel())
        .environmentObject(GoalsViewModel())
}
