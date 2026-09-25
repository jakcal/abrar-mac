import CoreText
import SwiftUI

enum QuranFont {
    private static let postScriptName = "AmiriQuran-Regular"

    static func register() {
        guard let url = Bundle.main.url(forResource: "AmiriQuran", withExtension: "ttf") else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    static func font(size: Double) -> Font {
        .custom(postScriptName, size: size)
    }

    static func arabicDigits(_ number: Int) -> String {
        let digits: [Character] = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
        return String(String(number).compactMap { $0.wholeNumberValue.map { digits[$0] } })
    }
}
