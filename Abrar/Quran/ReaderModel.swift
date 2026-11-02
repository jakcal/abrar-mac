import Foundation
import Observation

@MainActor
@Observable
final class ReaderModel {
    private(set) var surahs: [Surah] = []
    private(set) var filteredSurahs: [Surah] = []
    private(set) var ayahs: [Ayah] = []
    /// English translation of the selected surah, keyed by ayah number.
    private(set) var translations: [Int: String] = [:]
    private(set) var juzs: [QuranMark] = []
    private(set) var pages: [QuranMark] = []
    /// Topmost ayah on screen, for the location shown in the title bar.
    private(set) var topAyah: Int?
    private(set) var bookmarks: [Bookmark] = []
    private(set) var errorMessage: String?
    var showsGoTo = false
    /// Ayah number the reader should scroll to; cleared by the view once handled.
    var scrollTarget: Int?

    var searchText = "" {
        didSet { applySearch() }
    }

    var selectedSurahID: Int? {
        didSet {
            guard selectedSurahID != oldValue else { return }
            loadAyahs()
        }
    }

    var selectedSurah: Surah? {
        surahs.first { $0.id == selectedSurahID }
    }

    @ObservationIgnored private let quran: QuranStore
    @ObservationIgnored private let library: LibraryRepository
    @ObservationIgnored private var visibleAyahs: Set<Int> = []
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    init(quran: QuranStore, library: LibraryRepository) {
        self.quran = quran
        self.library = library
    }

    func load() {
        do {
            surahs = try quran.surahs()
            bookmarks = try library.bookmarks()
            juzs = try quran.juzStarts()
            pages = try quran.pageStarts()
            errorMessage = nil
            applySearch()
            if selectedSurahID == nil, let position = try library.readingPosition() {
                open(surah: position.surah, ayah: position.ayah)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func open(surah: Int, ayah: Int = 1) {
        selectedSurahID = surah
        scrollTarget = ayah
    }

    /// Opens "2:255", or an ayah of the current surah when given just a number. False when there's no such ayah.
    @discardableResult
    func go(to query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let reference = AyahReference(trimmed)
            ?? Int(trimmed).flatMap { ayah in selectedSurahID.map { AyahReference(surah: $0, ayah: ayah) } }
        guard let reference, let surah = surahs.first(where: { $0.id == reference.surah }),
              reference.ayah <= surah.ayahCount else { return false }
        open(surah: reference.surah, ayah: reference.ayah)
        return true
    }

    func juz(surah: Int, ayah: Int) -> Int? { juzs.index(surah: surah, ayah: ayah) }
    func page(surah: Int, ayah: Int) -> Int? { pages.index(surah: surah, ayah: ayah) }

    /// The juz this ayah opens, if any. Skips juz 1, which opens with the Quran itself.
    func startsJuz(_ ayah: Ayah) -> Int? {
        juzs.first { $0.surah == ayah.surah && $0.ayah == ayah.number && $0.id > 1 }?.id
    }

    func translation(of ayah: Ayah) -> String? { translations[ayah.number] }

    func ayahAppeared(_ number: Int) {
        visibleAyahs.insert(number)
        updateTopAyah()
        scheduleSave()
    }

    func ayahDisappeared(_ number: Int) {
        visibleAyahs.remove(number)
        updateTopAyah()
    }

    private func updateTopAyah() {
        let top = visibleAyahs.min()
        if top != topAyah { topAyah = top }
    }

    func isBookmarked(_ ayah: Ayah) -> Bool {
        bookmarks.contains { $0.surah == ayah.surah && $0.ayah == ayah.number }
    }

    func toggleBookmark(_ ayah: Ayah) {
        do {
            if isBookmarked(ayah) {
                try library.removeBookmark(surah: ayah.surah, ayah: ayah.number)
            } else {
                try library.addBookmark(surah: ayah.surah, ayah: ayah.number)
            }
            bookmarks = try library.bookmarks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeBookmark(_ bookmark: Bookmark) {
        do {
            try library.removeBookmark(surah: bookmark.surah, ayah: bookmark.ayah)
            bookmarks = try library.bookmarks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func surahName(_ id: Int) -> String {
        surahs.first { $0.id == id }?.nameTransliterated ?? "Surah \(id)"
    }

    private func applySearch() {
        filteredSurahs = (try? quran.searchSurahs(searchText)) ?? surahs
    }

    private func loadAyahs() {
        visibleAyahs.removeAll()
        topAyah = nil
        guard let selectedSurahID else {
            ayahs = []
            translations = [:]
            return
        }
        do {
            ayahs = try quran.ayahs(inSurah: selectedSurahID)
            translations = (try? quran.translations(inSurah: selectedSurahID)) ?? [:]
            errorMessage = nil
        } catch {
            ayahs = []
            translations = [:]
            errorMessage = error.localizedDescription
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            self?.saveReadingPosition()
        }
    }

    private func saveReadingPosition() {
        guard let surah = selectedSurahID, let ayah = visibleAyahs.min() else { return }
        try? library.saveReadingPosition(ReadingPosition(surah: surah, ayah: ayah))
    }
}
