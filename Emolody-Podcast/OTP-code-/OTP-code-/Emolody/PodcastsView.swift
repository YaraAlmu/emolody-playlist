//
//  PodcastsView.swift
//  Emolody
//
//  Created by toleen alghamdi on 14/04/1447 AH.
//

import SwiftUI
import WebKit

struct PodcastsView: View {
    struct Mood: Identifiable, Hashable {
        var id: String { title }
        let emoji: String
        let title: String
    }
    struct PodcastItem: Identifiable {
        let id = UUID()
        let title: String
        let author: String
        let short: String
        let category: String
        let mood: Mood
        let color: Color
        let podcastID: String
    }
    
    @State private var selectedCategory: Mood? = nil

    let categories: [Mood] = [
        .init(emoji: "♾️", title: "All"),
        .init(emoji: "😂", title: "Comedy"),
        .init(emoji: "🧘‍♂️", title: "Wellness"),
        .init(emoji: "🔮", title: "Motivational"),
        .init(emoji: "...", title: "Other")
    ]
    
    init() {
        _selectedCategory = State(initialValue: categories.first)
    }
    
    var podcasts: [PodcastItem] { [
        //MARK: Comedy
        .init(title: "Kefaya Ba2a ( كفاية بقى)", author: "Alaa El Sheikh", short: "Kefaya Ba2a is a comedic Arabic podcast hosted", category: "Comedy", mood: categories[1], color: .purple, podcastID: "1553857121"),
        .init(title: "Kalam Mn Lahb | كلام من لهب", author: "Ashraf & Fekry", short: "Kalam Mn Lahb is a comedic Arabic podcast hosted", category: "Comedy", mood: categories[1], color: .purple, podcastID: "1700537919"),
        .init(title: "The Comedian’s Comedian Podcast", author: "Stuart Goldsmith", short: "comedy interview show", category: "Comedy", mood: categories[1], color: .purple, podcastID: "513734888"),
        .init(title: "Off Menu with Ed Gamble and James Acaster", author: "James Acaster, Ed Gamble", short: "comedy-food podcast", category: "Comedy", mood: categories[1], color: .purple, podcastID: "1442950743"),
        .init(title: "The Bald Brothers Podcast", author: "KevOnStage & Tony Baker", short: "relaxed comedy podcast", category: "Comedy", mood: categories[1], color: .purple, podcastID: "1652772265"),
        
        //MARK: Wellness
        .init(title: "The Wellness Scoop", author: "Ella Mills", short: "The Wellness Scoop is a weekly wellness", category: "Wellness", mood: categories[2], color: .blue, podcastID: "1428704212"),
        .init(title: "Wellness Her Way", author: "Gracie Norton", short: "A wellness podcast hosted by Gracie Norton", category: "Wellness", mood: categories[2], color: .blue, podcastID: "1714005969"),
        .init(title: "The Nature of Wellness", author: "The Nature of Wellness", short: "explores natural living", category: "Wellness", mood: categories[2], color: .blue, podcastID: "1651041551"),
        .init(title: "Wellness Within Reach", author: " Dr. Reham Garash", short: "This podcast challenges the traditional", category: "Wellness", mood: categories[2], color: .blue, podcastID: "1588927225"),
        .init(title: "العافية 360 – Wellness360", author: "EMPWR House / EMPWR Inc", short: "Wellness360 is a conversational", category: "Wellness", mood: categories[2], color: .blue, podcastID: "1673246043"),
        
        //MARK: Motivation
        .init(title: "Minutes Motivation – 7", author: "Samer Chidiac – سامر الشدياق", short: "7 Minutes Motivation is a short Arabic", category: "Motivation", mood: categories[3], color: .orange, podcastID: "532861003"),
        .init(title: "ا - تطوير الذات", author: "أسامة جاد", short: "A self-development Arabic podcast", category: "Motivation", mood: categories[3], color: .orange, podcastID: "1647662614"),
        .init(title: "ذات", author: "Thmanyah", short: "sharing intimate real-life stories", category: "Motivation", mood: categories[3], color: .orange, podcastID: "1634106069"),
        .init(title: "The Mindset Mentor", author: "Rob Dial", short: "A motivational self-development podcast", category: "Motivation", mood: categories[3], color: .orange, podcastID: "1033048640"),
        .init(title: "The Happiness Lab", author: "Dr. Laurie Santos", short: "The Happiness Lab is hosted", category: "Motivation", mood: categories[3], color: .orange, podcastID: "1501593904"),
        
        //MARK: Other
        .init(title: "Maharat Podcastb", author: "مدار Maddar", short: "In each episode we explore a new skill", category: "Educational", mood: categories[4], color: .green, podcastID: "1793572694"),
        .init(title: "Arabs and Football", author: "SBS", short: " This podcast explores the historical", category: "Sports", mood: categories[4], color: .black, podcastID: "1649273970"),
        .init(title: "The Alpha Talks Show: Arabic Edition", author: "Seif El Hakim", short: "أسرع بودكاست نمواً في الخليج", category: "Talk Show", mood: categories[4], color: .yellow, podcastID: "1795292625"),
        .init(title: "Hard Fork", author: "Kevin Roose & Casey Newton", short: "A weekly podcast where Kevin Roose", category: "Technology", mood: categories[4], color: .brown, podcastID: "1528594034"),
        .init(title: "The Talk Show With John Gruber", author: "John Gruber", short: "A long-form technology talk show", category: "Talk Show", mood: categories[4], color: .gray, podcastID: "528458508")
    ]
    }
    
    var filtered: [PodcastItem] {
        if let category = selectedCategory {
            if category.title == "All" {
                return podcasts.shuffled()
            } else {
                return podcasts.filter { $0.mood == category }
            }
        }
        return podcasts
    }
    
    var body: some View {
        ZStack {
            AppScreenBackground()
            
            VStack(spacing: 16) {
                Spacer().frame(height: 12)
                
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Podcast Collections")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Brand.textPrimary)
                    Text("Select a podcast category to explore")
                        .font(.system(size: 15))
                        .foregroundStyle(Brand.textSecondary)
                }
                .padding(.horizontal, 20)
                
                ScrollView {
                    VStack(spacing: 18) {
                        // Categories
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Choose Podcast Category 🎧")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Brand.textPrimary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(categories) { category in
                                    MoodRow(mood: category,
                                            isSelected: category == selectedCategory) {
                                        withAnimation(.easeInOut) {
                                            selectedCategory = (selectedCategory == category) ? nil : category
                                        }
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 6)
                        .padding(.horizontal, 18)

                        // Title
                        HStack {
                            Text(selectedCategory?.title ?? "All Podcasts")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Brand.textPrimary)
                            Spacer()
                            if let selected = selectedCategory {
                                Text("\(selected.emoji) \(selected.title)")
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.textSecondary)
                            }
                        }
                        .padding(.horizontal, 18)
                        
                        // Cards
                        VStack(spacing: 12) {
                            ForEach(filtered) { p in
                                NavigationLink(destination: PodcastWebView(podcastURL: p.podcastID)) {
                                    PodcastCard(podcast: p)
                                    
                                        .padding(.horizontal, 18)
                                }
                            }
                        }
                        
                        Spacer(minLength: 60)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle("Podcasts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MoodRow: View {
    let mood: PodcastsView.Mood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Brand.primary : Color.gray.opacity(0.35), lineWidth: isSelected ? 3 : 1.5)
                        .frame(width: 28, height: 28)
                    if isSelected {
                        Circle()
                            .fill(Brand.primary)
                            .frame(width: 12, height: 12)
                    }
                }
                Text("\(mood.emoji) \(mood.title)")
                    .foregroundStyle(Brand.textPrimary)
                Spacer()
            }
            .padding(10)
        }
        .buttonStyle(.plain)
    }
}

private struct PodcastCard: View {
    let podcast: PodcastsView.PodcastItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(podcast.color.opacity(0.3))
                    .frame(width: 56, height: 56)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(podcast.title).font(.system(size: 16, weight: .semibold))
                Text(podcast.author).font(.system(size: 13)).foregroundColor(.gray)
                Text(podcast.short).font(.system(size: 13)).foregroundColor(.black.opacity(0.6)).lineLimit(2)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 6, y: 4)
    }
}

struct PodcastWebView: UIViewRepresentable {
    let podcastURL: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        
        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body { margin:0; padding:0; background-color:black; }
            iframe { border:none; width:100%; height:100vh; }
        </style>
        </head>
        <body>
        <iframe src="https://pod.link/\(podcastURL)" allow="autoplay; encrypted-media" allowfullscreen></iframe>
        </body>
        </html>
        """
        
        webView.loadHTMLString(embedHTML, baseURL: nil)
        webView.scrollView.isScrollEnabled = true
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

 

