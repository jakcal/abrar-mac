import Foundation

/// One dhikr in a daily set, said `count` times.
struct AdhkarItem: Identifiable, Hashable, Sendable {
    enum Content: Hashable, Sendable {
        case arabic(String)
        /// Ayahs read from the bundled Quran text so they match the reader exactly.
        case quran(surah: Int, ayahs: ClosedRange<Int>, bismillah: Bool)
    }

    let id: String
    let title: String?
    let text: Content
    let translation: String
    let source: String
    let count: Int
}

enum AdhkarCatalog {
    static func items(for session: AdhkarSession) -> [AdhkarItem] {
        switch session {
        case .morning: morning
        case .evening: evening
        case .night: night
        }
    }

    // MARK: - Shared

    private static let ayatAlKursi = AdhkarItem(
        id: "kursi", title: "Ayat al-Kursi",
        text: .quran(surah: 2, ayahs: 255...255, bismillah: false),
        translation: "Allah: there is no god but Him, the Ever-Living, the Sustainer of all.",
        source: "Al-Baqarah 2:255", count: 1
    )

    private static func qul(_ surah: Int, count: Int, source: String) -> AdhkarItem {
        let (name, ayahs, translation): (String, ClosedRange<Int>, String) = switch surah {
        case 112: ("Al-Ikhlas", 1...4, "Say: He is Allah, the One. Allah, the Eternal Refuge. He neither begets nor was He begotten, and there is none comparable to Him.")
        case 113: ("Al-Falaq", 1...5, "Say: I seek refuge in the Lord of daybreak, from the evil of what He created, from the evil of darkness when it settles, from the evil of those who blow on knots, and from the evil of an envier when he envies.")
        default: ("An-Nas", 1...6, "Say: I seek refuge in the Lord of mankind, the King of mankind, the God of mankind, from the evil of the retreating whisperer, who whispers in the hearts of mankind, from among jinn and mankind.")
        }
        return AdhkarItem(
            id: "qul\(surah)", title: name,
            text: .quran(surah: surah, ayahs: ayahs, bismillah: true),
            translation: translation, source: source, count: count
        )
    }

    private static let quls = [112, 113, 114].map { qul($0, count: 3, source: "Abu Dawud, Tirmidhi") }

    private static let sayyidAlIstighfar = AdhkarItem(
        id: "sayyid-istighfar", title: "Sayyid al-Istighfar",
        text: .arabic("اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَىٰ عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ"),
        translation: "O Allah, You are my Lord, there is no god but You. You created me and I am Your servant, and I keep Your covenant and promise as best I can. I seek refuge in You from the evil I have done. I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for none forgives sins but You.",
        source: "Bukhari", count: 1
    )

    private static let bismillahAlladhi = AdhkarItem(
        id: "bismillah-alladhi", title: nil,
        text: .arabic("بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ"),
        translation: "In the name of Allah, with whose name nothing on earth or in the heavens can cause harm, and He is the All-Hearing, the All-Knowing.",
        source: "Abu Dawud, Tirmidhi", count: 3
    )

    private static let raditu = AdhkarItem(
        id: "raditu", title: nil,
        text: .arabic("رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا"),
        translation: "I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad ﷺ as my Prophet.",
        source: "Abu Dawud, Tirmidhi", count: 3
    )

    private static let hasbiyallah = AdhkarItem(
        id: "hasbiyallah", title: nil,
        text: .arabic("حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ، عَلَيْهِ تَوَكَّلْتُ، وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ"),
        translation: "Allah is sufficient for me. There is no god but Him. In Him I put my trust, and He is the Lord of the Mighty Throne.",
        source: "Abu Dawud", count: 7
    )

    private static let yaHayyu = AdhkarItem(
        id: "ya-hayyu", title: nil,
        text: .arabic("يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَىٰ نَفْسِي طَرْفَةَ عَيْنٍ"),
        translation: "O Ever-Living, O Sustainer, in Your mercy I seek relief. Set right all my affairs and do not leave me to myself for the blink of an eye.",
        source: "An-Nasa'i", count: 1
    )

    private static let afini = AdhkarItem(
        id: "afini", title: nil,
        text: .arabic("اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَٰهَ إِلَّا أَنْتَ"),
        translation: "O Allah, grant me well-being in my body. O Allah, grant me well-being in my hearing. O Allah, grant me well-being in my sight. There is no god but You.",
        source: "Abu Dawud", count: 3
    )

    private static let tahlil = AdhkarItem(
        id: "tahlil-10", title: nil,
        text: .arabic("لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ"),
        translation: "There is no god but Allah alone, without partner. His is the dominion and His is the praise, and He has power over all things.",
        source: "Ahmad, An-Nasa'i", count: 10
    )

    private static let subhanallahWaBihamdihi = AdhkarItem(
        id: "subhanallah-100", title: nil,
        text: .arabic("سُبْحَانَ اللَّهِ وَبِحَمْدِهِ"),
        translation: "Glory and praise be to Allah.",
        source: "Muslim", count: 100
    )

    private static let salawat = AdhkarItem(
        id: "salawat-10", title: nil,
        text: .arabic("اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَىٰ نَبِيِّنَا مُحَمَّدٍ"),
        translation: "O Allah, send blessings and peace upon our Prophet Muhammad.",
        source: "At-Tabarani", count: 10
    )

    // MARK: - Sets

    static let morning: [AdhkarItem] = [ayatAlKursi] + quls + [
        AdhkarItem(
            id: "asbahna", title: nil,
            text: .arabic("أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَٰذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَٰذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ"),
            translation: "We have entered the morning and the dominion belongs to Allah. Praise be to Allah; there is no god but Allah alone, without partner. His is the dominion and the praise, and He has power over all things. My Lord, I ask You for the good of this day and what follows it, and seek refuge in You from the evil of this day and what follows it. My Lord, I seek refuge in You from laziness and the misery of old age, and from punishment in the Fire and in the grave.",
            source: "Muslim", count: 1
        ),
        AdhkarItem(
            id: "bika-asbahna", title: nil,
            text: .arabic("اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ"),
            translation: "O Allah, by You we enter the morning and by You we enter the evening, by You we live and by You we die, and to You is the resurrection.",
            source: "Tirmidhi", count: 1
        ),
        sayyidAlIstighfar, bismillahAlladhi, raditu, hasbiyallah, yaHayyu, afini,
        AdhkarItem(
            id: "adada-khalqihi", title: nil,
            text: .arabic("سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ"),
            translation: "Glory and praise be to Allah, as many times as the number of His creation, as much as pleases Him, as heavy as His Throne, and as abundant as the ink of His words.",
            source: "Muslim", count: 3
        ),
        tahlil, subhanallahWaBihamdihi,
        AdhkarItem(
            id: "istighfar-100", title: nil,
            text: .arabic("أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ"),
            translation: "I seek Allah's forgiveness and turn to Him in repentance.",
            source: "Bukhari, Muslim", count: 100
        ),
        salawat,
    ]

    static let evening: [AdhkarItem] = [ayatAlKursi] + quls + [
        AdhkarItem(
            id: "amsayna", title: nil,
            text: .arabic("أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَٰذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَٰذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا، رَبِّ أَعُوذُ بِكَ مِنَ الْكَسَلِ وَسُوءِ الْكِبَرِ، رَبِّ أَعُوذُ بِكَ مِنْ عَذَابٍ فِي النَّارِ وَعَذَابٍ فِي الْقَبْرِ"),
            translation: "We have entered the evening and the dominion belongs to Allah. Praise be to Allah; there is no god but Allah alone, without partner. His is the dominion and the praise, and He has power over all things. My Lord, I ask You for the good of this night and what follows it, and seek refuge in You from the evil of this night and what follows it. My Lord, I seek refuge in You from laziness and the misery of old age, and from punishment in the Fire and in the grave.",
            source: "Muslim", count: 1
        ),
        AdhkarItem(
            id: "bika-amsayna", title: nil,
            text: .arabic("اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ"),
            translation: "O Allah, by You we enter the evening and by You we enter the morning, by You we live and by You we die, and to You is the final return.",
            source: "Tirmidhi", count: 1
        ),
        sayyidAlIstighfar, bismillahAlladhi, raditu, hasbiyallah, yaHayyu, afini,
        AdhkarItem(
            id: "kalimat", title: nil,
            text: .arabic("أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ"),
            translation: "I seek refuge in the perfect words of Allah from the evil of what He has created.",
            source: "Muslim", count: 3
        ),
        tahlil, subhanallahWaBihamdihi, salawat,
    ]

    static let night: [AdhkarItem] = [
        ayatAlKursi,
        AdhkarItem(
            id: "baqarah-end", title: "End of Al-Baqarah",
            text: .quran(surah: 2, ayahs: 285...286, bismillah: false),
            translation: "The last two ayahs of Al-Baqarah suffice whoever recites them at night.",
            source: "Al-Baqarah 2:285–286 · Bukhari, Muslim", count: 1
        ),
    ] + [112, 113, 114].map { qul($0, count: 3, source: "Bukhari") } + [
        AdhkarItem(
            id: "bismika-rabbi", title: nil,
            text: .arabic("بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ"),
            translation: "In Your name, my Lord, I lie down and by You I rise. If You take my soul, have mercy on it, and if You return it, protect it as You protect Your righteous servants.",
            source: "Bukhari, Muslim", count: 1
        ),
        AdhkarItem(
            id: "qini", title: nil,
            text: .arabic("اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ"),
            translation: "O Allah, protect me from Your punishment on the Day You resurrect Your servants.",
            source: "Abu Dawud", count: 3
        ),
        AdhkarItem(
            id: "tasbih-33", title: nil,
            text: .arabic("سُبْحَانَ اللَّهِ"),
            translation: "Glory be to Allah.",
            source: "Bukhari, Muslim", count: 33
        ),
        AdhkarItem(
            id: "tahmid-33", title: nil,
            text: .arabic("الْحَمْدُ لِلَّهِ"),
            translation: "All praise is due to Allah.",
            source: "Bukhari, Muslim", count: 33
        ),
        AdhkarItem(
            id: "takbir-34", title: nil,
            text: .arabic("اللَّهُ أَكْبَرُ"),
            translation: "Allah is the Greatest.",
            source: "Bukhari, Muslim", count: 34
        ),
        AdhkarItem(
            id: "bismika-amutu", title: nil,
            text: .arabic("بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا"),
            translation: "In Your name, O Allah, I die and I live.",
            source: "Bukhari", count: 1
        ),
    ]
}
