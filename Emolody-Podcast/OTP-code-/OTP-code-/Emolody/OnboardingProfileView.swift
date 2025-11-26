//
//  OnboardingProfileView.swift
//  Emolody
//
//  Created by toleen alghamdi on 20/04/1447 AH.
import SwiftUI

struct OnboardingProfileView: View {
    @ObservedObject var user: UserStore
    var canEditName: Bool = true          // ← جديد
    var onDone: () -> Void

    @State private var name: String = ""

    private let allGenres = ["Pop","Hip-Hop","R&B","EDM","Chill","Classical","Rock","Jazz"]
    private let allActivities = ["Workout","Study","Commute","Relax","Party","Reading"]

    private let chipColumns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

    var body: some View {
        ZStack { AppScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    Text(canEditName ? "Complete your profile" : "Edit your preferences")
                        .font(.title2.bold())
                        .foregroundStyle(Brand.textPrimary)

                    // الاسم: يظهر فقط في الأونبوردنق
                    if canEditName {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your name").font(.headline).foregroundStyle(Brand.textPrimary)
                            TextField("Enter your name", text: $name)
                                .textInputAutocapitalization(.words)
                                .padding()
                                .background(Brand.card)
                                .cornerRadius(12)
                        }
                        .appCard()
                    }

                    // الأنواع
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Favorite genres").font(.headline).foregroundStyle(Brand.textPrimary)
                        LazyVGrid(columns: chipColumns, spacing: 8) {
                            ForEach(allGenres, id: \.self) { t in
                                SelectChip(title: t, isSelected: user.genres.contains(t)) {
                                    toggle(&user.genres, t)
                                }
                            }
                        }
                    }
                    .appCard()

                    // الأنشطة
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activities").font(.headline).foregroundStyle(Brand.textPrimary)
                        LazyVGrid(columns: chipColumns, spacing: 8) {
                            ForEach(allActivities, id: \.self) { t in
                                SelectChip(title: t, isSelected: user.activities.contains(t)) {
                                    toggle(&user.activities, t)
                                }
                            }
                        }
                    }
                    .appCard()

                    Button {
                        if canEditName {
                            user.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        user.save()
                        onDone()
                    } label: {
                        Text("Save & continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Brand.primary)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 4)
                }
                .padding()
            }
        }
        .onAppear { name = user.name }
        .navigationTitle(canEditName ? "Profile setup" : "Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ set: inout Set<String>, _ item: String) {
        if set.contains(item) { set.remove(item) } else { set.insert(item) }
    }
}

private struct SelectChip: View {
    let title: String
    let isSelected: Bool
    let tap: () -> Void
    var body: some View {
        Button(action: tap) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? Brand.primary : Brand.card)
                .foregroundStyle(isSelected ? .white : Brand.textPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isSelected ? Brand.primary : Color.gray.opacity(0.25), lineWidth: 1)
                )
                .cornerRadius(18)
        }
        .buttonStyle(.plain)
    }
}
