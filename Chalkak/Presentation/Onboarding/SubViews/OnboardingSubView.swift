//
//  OnboardingSubView.swift
//  Chalkak
//
//  Created by Murphy on 8/19/25.
//
import SwiftUI

struct Onboard: View {
    let ImageName: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 40) {
            Image(ImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 346)
            VStack (spacing: 12){
                Text(title)
                    .foregroundStyle(Color.matcha200)
                    .font(.title)
                    .fontWeight(.bold)
                Text(description)
                    .foregroundStyle(Color.matcha50)
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
