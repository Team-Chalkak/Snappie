//
//  OnboardingSubView.swift
//  Chalkak
//
//  Created by Murphy on 8/19/25.
//
import SwiftUI

struct Onboard: View {
    let ImageName: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    
    var body: some View {
        VStack {
            Image(ImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 346)
                .padding(.bottom, 40)
            Text(title)
                .foregroundStyle(Color.matcha200)
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 12)
            Text(description)
                .foregroundStyle(Color.matcha50)
                .font(.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: 80, alignment: .top)
        }
    }
}
