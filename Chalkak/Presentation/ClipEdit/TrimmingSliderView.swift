//
//  TrimmingSliderView.swift
//  Chalkak
//
//  Created by Youbin on 7/14/25.
//

import SwiftUI
import AVKit

struct TrimmingSliderView: View {
    @ObservedObject var viewModel: ClipEditViewModel
    
    @State private var sliderWidth: CGFloat = 0
    
    private let handleWidth: CGFloat = 15
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                VStack {
                    // MARK: 썸네일 뷰
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(viewModel.thumbnails, id: \.self) { thumbnail in
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 60)
                                    .clipped()
                            }
                        }
                    }
                    .frame(height: 60)
                    .cornerRadius(8)
                    .overlay(
                        trimmingHandles(geometry: geometry)
                    )
                    .onAppear {
                        self.sliderWidth = geometry.size.width
                    }
                }
            }
            .frame(height: 60)
            .padding(.horizontal)
        }
    }
    
    // MARK: - 트리밍 핸들
    private func trimmingHandles(geometry: GeometryProxy) -> some View {
        let totalWidth = geometry.size.width
        let startPosition = CGFloat(viewModel.startPoint / viewModel.duration) * totalWidth
        let endPosition = CGFloat(viewModel.endPoint / viewModel.duration) * totalWidth
        
        return ZStack {
            // MARK: 왼쪽 핸들 + 어둡게 처리
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: startPosition)
                
                VStack(spacing: 0) {
                    Rectangle().frame(height: 4)
                    HStack(spacing: 0) {
                        Rectangle().frame(width: 4)
                        Spacer()
                        Rectangle().frame(width: 4)
                    }
                    Rectangle().frame(height: 4)
                }
                .frame(width: endPosition - startPosition)
                .background(.clear)
                .foregroundColor(.yellow)
                
                Rectangle()
                    .fill(Color.black.opacity(0.5))
            }
            
            // MARK: 핸들러
            HStack(spacing: 0) {
                // 시작 핸들러
                handleView()
                    .position(x: startPosition, y: 30)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newStart = max(0, min(gesture.location.x / totalWidth * viewModel.duration, viewModel.endPoint - 0.1))
                                viewModel.updateStart(newStart)
                            }
                    )
                
                // 끝 핸들러
                handleView()
                    .position(x: endPosition, y: 30)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newEnd = min(viewModel.duration, max(gesture.location.x / totalWidth * viewModel.duration, viewModel.startPoint + 0.1))
                                viewModel.updateEnd(newEnd)
                            }
                    )
            }
        }
    }
    
    private func handleView() -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.yellow)
            .frame(width: handleWidth, height: 60)
    }
}

#Preview {
    ClipEditView()
}
