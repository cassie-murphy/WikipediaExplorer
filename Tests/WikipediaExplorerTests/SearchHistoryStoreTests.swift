import Foundation
import Testing
@testable import WikipediaExplorer

struct SearchHistoryStoreTests {

    @Test func testRecordAndLoadSearchTerms() {
        // Arrange
        let store = MockSearchHistoryStore()

        // Act
        store.record("First Search")
        store.record("Second Search")
        store.record("First Search") // Duplicate should move to front

        let results = store.load()

        // Assert
        #expect(results.count == 2)
        #expect(results[0] == "First Search") // Most recent
        #expect(results[1] == "Second Search")
        #expect(store.recordCalls.count == 3)
        #expect(store.loadCallCount == 1)
    }

    @Test func testRecordEmptyOrWhitespaceTerms() {
        // Arrange
        let store = MockSearchHistoryStore()

        // Act
        store.record("")
        store.record("   ")
        store.record("\n\t")
        store.record("Valid Term")

        let results = store.load()

        // Assert
        #expect(results.count == 1)
        #expect(results[0] == "Valid Term")
    }

    @Test func testRecordTermLimit() {
        // Arrange
        let store = MockSearchHistoryStore()

        // Act - Add more than 10 terms
        for i in 1...15 {
            store.record("Term \(i)")
        }

        let results = store.load()

        // Assert
        #expect(results.count == 10) // Should be limited to 10
        #expect(results[0] == "Term 15") // Most recent
        #expect(results[9] == "Term 6") // Oldest kept
        #expect(!results.contains("Term 1")) // Oldest should be removed
    }

    @Test func testRemoveSearchTerms() {
        // Arrange
        let store = MockSearchHistoryStore()
        store.preloadItems(["First", "Second", "Third"])

        // Act
        store.remove(at: IndexSet([1])) // Remove "Second"

        // Assert
        let results = store.load()
        #expect(results.count == 2)
        #expect(results.contains("Second") == false)
        #expect(results.contains("First") == true)
        #expect(results.contains("Third") == true)
        #expect(store.removeCalls.count == 1)
    }

    @Test func testClearAllSearchTerms() {
        // Arrange
        let store = MockSearchHistoryStore()
        store.preloadItems(["First", "Second", "Third"])

        // Act
        store.clear()

        // Assert
        let results = store.load()
        #expect(results.isEmpty)
        #expect(store.clearCallCount == 1)
    }

    @Test func testCaseInsensitiveDuplicateRemoval() {
        // Arrange
        let store = MockSearchHistoryStore()

        // Act
        store.record("Swift")
        store.record("swift") // Different case
        store.record("SWIFT") // Different case

        let results = store.load()

        // Assert
        #expect(results.count == 1)
        #expect(results[0] == "SWIFT") // Last one should be kept
    }

    @Test func testSearchHistoryOrdering() {
        // Arrange
        let store = MockSearchHistoryStore()

        // Act - Add items in order
        store.record("First")
        store.record("Second")
        store.record("Third")

        let results = store.load()

        // Assert - Should be in reverse order (most recent first)
        #expect(results[0] == "Third")
        #expect(results[1] == "Second")
        #expect(results[2] == "First")
    }

    @Test func testRecentSearchPromotion() {
        // Arrange
        let store = MockSearchHistoryStore()
        store.record("Old Search")
        store.record("Middle Search")
        store.record("Recent Search")

        // Act - Search for an old term again
        store.record("Old Search")

        let results = store.load()

        // Assert - Old search should be promoted to front
        #expect(results[0] == "Old Search")
        #expect(results[1] == "Recent Search")
        #expect(results[2] == "Middle Search")
        #expect(results.count == 3) // No duplicates
    }

    @Test func testTrimmingWhitespace() {
        // Arrange
        let store = MockSearchHistoryStore()

        // Act
        store.record("  Trimmed Term  ")
        store.record("\n\tAnother Term\t\n")

        let results = store.load()

        // Assert - Terms should be trimmed
        #expect(results.contains("Trimmed Term"))
        #expect(results.contains("Another Term"))
        #expect(!results.contains("  Trimmed Term  "))
    }
}
