import Foundation

/// Full-surah MP3 recitations (Hafs 'an Asim) from quran.com's QuranicAudio CDN.
/// `qdcID` is the quran.com recitation id, used to fetch per-ayah timings for the same files.
struct Reciter: Identifiable, Hashable, Sendable {
    let id: String
    let qdcID: Int
    let name: String
    let arabicName: String
    let style: String
    /// `String(format:)` pattern taking the surah number.
    let urlFormat: String

    var displayName: String { "\(name) (\(style))" }

    func remoteURL(forSurah surah: Int) -> URL? {
        URL(string: String(format: urlFormat, surah))
    }

    static let defaultID = "alafasy"

    private static let cdn = "https://download.quranicaudio.com/qdc/"

    static let all: [Reciter] = [
        Reciter(id: "abdulbasit", qdcID: 2, name: "Abdul Basit Abdul Samad", arabicName: "عبد الباسط عبد الصمد",
                style: "Murattal", urlFormat: cdn + "abdul_baset/murattal/%d.mp3"),
        Reciter(id: "abdulbasit-mujawwad", qdcID: 1, name: "Abdul Basit Abdul Samad", arabicName: "عبد الباسط عبد الصمد",
                style: "Mujawwad", urlFormat: cdn + "abdul_baset/mujawwad/%d.mp3"),
        Reciter(id: "sudais", qdcID: 3, name: "Abdur-Rahman as-Sudais", arabicName: "عبد الرحمن السديس",
                style: "Murattal", urlFormat: cdn + "abdurrahmaan_as_sudais/murattal/%d.mp3"),
        Reciter(id: "shatri", qdcID: 4, name: "Abu Bakr al-Shatri", arabicName: "أبو بكر الشاطري",
                style: "Murattal", urlFormat: cdn + "abu_bakr_shatri/murattal/%d.mp3"),
        Reciter(id: "rifai", qdcID: 5, name: "Hani ar-Rifai", arabicName: "هاني الرفاعي",
                style: "Murattal", urlFormat: cdn + "hani_ar_rifai/murattal/%d.mp3"),
        Reciter(id: "husary", qdcID: 6, name: "Mahmoud Khalil Al-Husary", arabicName: "محمود خليل الحصري",
                style: "Murattal", urlFormat: cdn + "khalil_al_husary/murattal/%d.mp3"),
        Reciter(id: "husary-muallim", qdcID: 12, name: "Mahmoud Khalil Al-Husary", arabicName: "محمود خليل الحصري",
                style: "Muallim", urlFormat: cdn + "khalil_al_husary/muallim/%d.mp3"),
        Reciter(id: "alafasy", qdcID: 7, name: "Mishary Alafasy", arabicName: "مشاري العفاسي",
                style: "Murattal", urlFormat: cdn + "mishari_al_afasy/murattal/%d.mp3"),
        Reciter(id: "minshawi", qdcID: 9, name: "Mohamed Siddiq Al-Minshawi", arabicName: "محمد صديق المنشاوي",
                style: "Murattal", urlFormat: cdn + "siddiq_minshawi/murattal/%d.mp3"),
        Reciter(id: "shuraym", qdcID: 10, name: "Sa'ud ash-Shuraym", arabicName: "سعود الشريم",
                style: "Murattal", urlFormat: cdn + "saud_ash-shuraym/murattal/%03d.mp3"),
    ]

    static func with(id: String) -> Reciter {
        all.first { $0.id == id } ?? all[0]
    }
}
