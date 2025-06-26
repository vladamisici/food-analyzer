import Foundation
import SwiftUI
import UIKit
import Combine

@MainActor
final class FoodAnalysisViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedImage: UIImage?
    @Published var analysisResult: FoodAnalysisResponse?
    @Published var isAnalyzing = false
    @Published var showImagePicker = false
    @Published var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var analysisHistory: [FoodAnalysisResponse] = []
    @Published var showResultDetails = false
    
    // MARK: - Dependencies
    private let apiService: APIServiceProtocol
    private let authRepository: AuthRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Analysis State
    @Published var analysisProgress: Double = 0.0
    @Published var analysisStep: AnalysisStep = .idle
    
    enum AnalysisStep: String, CaseIterable {
        case idle = "Ready to analyze"
        case uploading = "Uploading image..."
        case processing = "Analyzing nutrition..."
        case completed = "Analysis complete!"
        case failed = "Analysis failed"
        
        var icon: String {
            switch self {
            case .idle: return "camera.fill"
            case .uploading: return "arrow.up.circle.fill"
            case .processing: return "brain.head.profile"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "exclamationmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .idle: return Color.theme.textSecondary
            case .uploading: return Color.theme.primary
            case .processing: return Color.theme.secondary
            case .completed: return Color.theme.success
            case .failed: return Color.theme.error
            }
        }
    }
    
    // MARK: - Initialization
    init(
        apiService: APIServiceProtocol = APIService.shared,
        authRepository: AuthRepositoryProtocol = AuthRepository()
    ) {
        self.apiService = apiService
        self.authRepository = authRepository
        setupErrorHandling()
        loadCachedHistory()
    }
    
    // MARK: - Public Methods
    func selectImageFromLibrary() {
        imagePickerSource = .photoLibrary
        showImagePicker = true
    }
    
    func selectImageFromCamera() {
        imagePickerSource = .camera
        showImagePicker = true
    }
    
    func analyzeSelectedImage() async {
        guard let image = selectedImage else {
            showError(message: "Please select an image first")
            return
        }
        
        await analyzeFood(image: image)
    }
    
    func analyzeFood(image: UIImage) async {
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        analysisStep = .uploading
        analysisProgress = 0.0
        clearError()
        
        // Simulate progress for better UX
        startProgressSimulation()
        
        // Create metadata
        let metadata = createImageMetadata(for: image)
        
        // Perform analysis
        let result = await apiService.analyzeFood(image: image, metadata: metadata)
        
        // Stop progress simulation
        stopProgressSimulation()
        
        switch result {
        case .success(let response):
            analysisStep = .completed
            analysisProgress = 1.0
            analysisResult = response
            addToHistory(response)
            showResultDetails = true
            
            // Success haptic feedback
            if UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled") {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
            
        case .failure(let error):
            analysisStep = .failed
            showError(error)
            
            // Error haptic feedback
            if UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled") {
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
            }
        }
        
        isAnalyzing = false
        
        // Reset to idle after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if self.analysisStep == .completed || self.analysisStep == .failed {
                self.analysisStep = .idle
                self.analysisProgress = 0.0
            }
        }
    }
    
    func retryAnalysis() async {
        if let image = selectedImage {
            await analyzeFood(image: image)
        }
    }
    
    func clearSelection() {
        selectedImage = nil
        analysisResult = nil
        analysisStep = .idle
        analysisProgress = 0.0
        showResultDetails = false
        clearError()
    }
    
    func editAnalysis(_ analysis: FoodAnalysisResponse) {
        // TODO: Implement edit functionality
    }
    
    func shareAnalysis(_ analysis: FoodAnalysisResponse) {
        // TODO: Implement share functionality
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Private Methods
    private func createImageMetadata(for image: UIImage) -> FoodAnalysisRequest.ImageMetadata? {
        guard let originalData = image.jpegData(compressionQuality: 1.0),
              let compressedData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        return FoodAnalysisRequest.ImageMetadata(
            size: image.size,
            originalSize: originalData.count,
            compressedSize: compressedData.count
        )
    }
    
    private func startProgressSimulation() {
        // Simulate upload progress
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard self.isAnalyzing && self.analysisStep == .uploading else { return }
            
            withAnimation(.easeInOut(duration: 1.0)) {
                self.analysisProgress = 0.3
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                guard self.isAnalyzing else { return }
                
                self.analysisStep = .processing
                
                withAnimation(.easeInOut(duration: 2.0)) {
                    self.analysisProgress = 0.8
                }
            }
        }
    }
    
    private func stopProgressSimulation() {
        // This will be called when the actual API response comes back
    }
    
    private func addToHistory(_ analysis: FoodAnalysisResponse) {
        analysisHistory.insert(analysis, at: 0)
        
        // Keep only last 50 analyses
        if analysisHistory.count > 50 {
            analysisHistory = Array(analysisHistory.prefix(50))
        }
        
        saveHistoryToCache()
    }
    
    private func loadCachedHistory() {
        if let data = UserDefaults.standard.data(forKey: "analysisHistory"),
           let history = try? JSONDecoder().decode([FoodAnalysisResponse].self, from: data) {
            analysisHistory = history
        }
    }
    
    private func saveHistoryToCache() {
        if let data = try? JSONEncoder().encode(analysisHistory) {
            UserDefaults.standard.set(data, forKey: "analysisHistory")
        }
    }
    
    private func setupErrorHandling() {
        // Auto-clear errors after 5 seconds
        $showError
            .filter { $0 }
            .delay(for: .seconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.clearError()
            }
            .store(in: &cancellables)
    }
    
    private func showError(_ error: AppError) {
        errorMessage = error.userFriendlyMessage
        showError = true
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}