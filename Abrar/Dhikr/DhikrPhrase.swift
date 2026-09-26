import Foundation

/// A short phrase of remembrance used for reminders.
struct DhikrPhrase: Hashable, Identifiable, Sendable {
    let id: String
    let arabic: String
    let transliteration: String
    let meaning: String

    init(id: String, arabic: String, transliteration: String, meaning: String) {
        self.id = id
        self.arabic = arabic
        self.transliteration = transliteration
        self.meaning = meaning
    }

    init(custom: CustomDhikr) {
        self.init(id: custom.id.uuidString, arabic: "", transliteration: custom.text, meaning: "")
    }

    static let builtIn: [DhikrPhrase] = [
        DhikrPhrase(id: "astaghfirullah", arabic: "أَسْتَغْفِرُ اللَّهَ", transliteration: "Astaghfirullah", meaning: "I seek Allah's forgiveness"),
        DhikrPhrase(id: "alhamdulillah", arabic: "الْحَمْدُ لِلَّهِ", transliteration: "Alhamdulillah", meaning: "All praise is due to Allah"),
        DhikrPhrase(id: "subhanallah", arabic: "سُبْحَانَ اللَّهِ", transliteration: "SubhanAllah", meaning: "Glory be to Allah"),
        DhikrPhrase(id: "allahuakbar", arabic: "اللَّهُ أَكْبَرُ", transliteration: "Allahu Akbar", meaning: "Allah is the Greatest"),
        DhikrPhrase(id: "tahlil", arabic: "لَا إِلَٰهَ إِلَّا اللَّهُ", transliteration: "La ilaha illa Allah", meaning: "There is no god but Allah"),
        DhikrPhrase(id: "salawat", arabic: "اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ", transliteration: "Allahumma salli ala Muhammad", meaning: "O Allah, send blessings upon Muhammad"),
        DhikrPhrase(id: "subhanallahwabihamdihi", arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ", transliteration: "SubhanAllahi wa bihamdihi", meaning: "Glory and praise be to Allah"),
        DhikrPhrase(id: "hawqala", arabic: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", transliteration: "La hawla wa la quwwata illa billah", meaning: "There is no might nor power except with Allah"),
        DhikrPhrase(id: "hasbunallah", arabic: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ", transliteration: "Hasbunallahu wa ni'mal wakil", meaning: "Allah is sufficient for us, and He is the best Guardian"),
    ]

    static let defaultIDs: Set<String> = ["astaghfirullah", "alhamdulillah", "subhanallah", "allahuakbar", "salawat"]
}
