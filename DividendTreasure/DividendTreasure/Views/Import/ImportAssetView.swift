//
//  ImportAssetView.swift
//  DividendTreasure
//
//  导入资产页面 - 支持拍照、相册、手动添加
//

import SwiftUI
import SwiftData
import PhotosUI

struct ImportAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Portfolio.createdAt, order: .reverse) private var portfolios: [Portfolio]

    @State private var selectedPortfolio: Portfolio?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var showOCRReview = false
    @State private var ocrResult: OCRResult?
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 选择目标组合
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择目标组合")
                        .font(.headline)

                    if portfolios.isEmpty {
                        Text("请先创建投资组合")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("目标组合", selection: $selectedPortfolio) {
                            ForEach(portfolios) { portfolio in
                                Text(portfolio.name).tag(portfolio as Portfolio?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // 导入方式
                VStack(spacing: 16) {
                    Text("选择导入方式")
                        .font(.headline)

                    // 拍照导入
                    Button(action: {
                        showCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .frame(width: 40)
                            VStack(alignment: .leading) {
                                Text("拍照导入")
                                    .font(.headline)
                                Text("使用相机拍摄持仓截图")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 2)
                    }
                    .buttonStyle(.plain)

                    // 相册导入
                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.fill")
                                .font(.title2)
                                .frame(width: 40)
                            VStack(alignment: .leading) {
                                Text("相册导入")
                                    .font(.headline)
                                Text("从相册选择持仓截图")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 2)
                    }
                    .buttonStyle(.plain)

                    // 手动添加
                    NavigationLink(destination: {
                        if let portfolio = selectedPortfolio {
                            HoldingFormView(portfolio: portfolio)
                        } else {
                            Text("请先选择目标组合")
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .frame(width: 40)
                            VStack(alignment: .leading) {
                                Text("手动添加")
                                    .font(.headline)
                                Text("手动输入持仓信息")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 2)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("导入资产")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .sheet(isPresented: $showImagePicker, onDismiss: processImage) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showCamera, onDismiss: processImage) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showOCRReview) {
                if let result = ocrResult, let portfolio = selectedPortfolio {
                    OCRReviewView(ocrResult: result, portfolio: portfolio)
                }
            }
            .overlay {
                if isProcessing {
                    ProgressView("正在识别...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
            .alert("识别失败", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                selectedPortfolio = portfolios.first
            }
        }
    }

    private func processImage() {
        guard let image = selectedImage else { return }

        isProcessing = true

        OCRService.shared.recognizeStocks(from: image) { result in
            DispatchQueue.main.async {
                isProcessing = false

                switch result {
                case .success(let ocrRes):
                    self.ocrResult = ocrRes
                    self.showOCRReview = true
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
}

// MARK: - 图片选择器

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType

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

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ImportAssetView()
        .modelContainer(for: Portfolio.self, inMemory: true)
}
