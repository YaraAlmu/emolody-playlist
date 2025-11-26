//
//  UserStore.swift
//  Emolody
//
//  Created by toleen alghamdi on 14/04/1447 AH.
//
import SwiftUI
import Combine

final class UserStore: ObservableObject {
    // اسم المستخدم
    @AppStorage("user.name") private var storedName: String = ""
    @Published var name: String = ""

    // رقم الهاتف
    @AppStorage("user.phone") private var storedPhone: String = ""
    @Published var phone: String = ""

    // آخر مود محفوظ
    @AppStorage("user.lastMood") private var storedLastMood: String = ""
    @Published var lastMood: String = ""

    // حالة اتصال Apple Music
    @AppStorage("user.isAppleMusicConnected") private var storedAppleMusic: Bool = false
    @Published var isAppleMusicConnected: Bool = false

    // التفضيلات
    @AppStorage("user.genres") private var storedGenres: String = "" // CSV
    @Published var genres: Set<String> = []

    @AppStorage("user.activities") private var storedActivities: String = "" // CSV
    @Published var activities: Set<String> = []

    init() {
        name = storedName
        phone = storedPhone
        lastMood = storedLastMood
        isAppleMusicConnected = storedAppleMusic
        genres = Set(storedGenres.split(separator: ",").map { String($0) })
        activities = Set(storedActivities.split(separator: ",").map { String($0) })
    }

    func save() {
        storedName = name
        storedPhone = phone
        storedLastMood = lastMood
        storedAppleMusic = isAppleMusicConnected
        storedGenres = genres.joined(separator: ",")
        storedActivities = activities.joined(separator: ",")
    }

    func connectAppleMusic() {
        isAppleMusicConnected = true
        save()
    }

    func disconnectAppleMusic() {
        isAppleMusicConnected = false
        save()
    }

    func clear() {
        name = ""
        phone = ""
        lastMood = ""
        isAppleMusicConnected = false
        genres.removeAll()
        activities.removeAll()
        save()
    }
}
