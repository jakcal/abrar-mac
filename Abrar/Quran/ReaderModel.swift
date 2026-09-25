import Foundation
import Observation

@MainActor
@Observable
final class ReaderModel {
    private(set) var surahs: [Surah] = []
    private(set) var filteredSurahs: [Surah] = []
    private(set) var ayahs: [Ayah] = []
    private(set) var bookmarks: [Bookmark] = []
    private(set) var errorMessage: String?
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

    func ayahAppeared(_ number: Int) {
        visibleAyahs.insert(number)
        scheduleSave()
    }

    func ayahDisappeared(_ number: Int) {
        visibleAyahs.remove(number)
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
        guard let selectedSurahID else {
            ayahs = []
            return
        }
        do {
            ayahs = try quran.ayahs(inSurah: selectedSurahID)
        } catch {
            ayahs = []
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
