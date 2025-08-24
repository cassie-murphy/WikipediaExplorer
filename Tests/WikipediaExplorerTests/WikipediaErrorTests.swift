import Testing
import Foundation
@testable import WikipediaExplorer

struct WikipediaErrorTests {
    
    @Test func testErrorDescriptionsAreUserFriendly() {
        let errors = WikipediaError.testCases
        
        for error in errors {
            let description = error.errorDescription
            #expect(description != nil, "Error \(error) should have a description")
            #expect(!description!.isEmpty, "Error \(error) description should not be empty")
            
            // Descriptions should be user-friendly (no technical jargon)
            #expect(!description!.contains("HTTP"), "Description should not contain HTTP: \(description!)")
            #expect(!description!.contains("JSON"), "Description should not contain JSON: \(description!)")
            #expect(!description!.contains("URLError"), "Description should not contain URLError: \(description!)")
        }
    }
    
    @Test func testRetryFlagsAreCorrect() {
        let retryableErrors = WikipediaError.retryableErrors
        let nonRetryableErrors = WikipediaError.nonRetryableErrors
        
        for error in retryableErrors {
            #expect(error.shouldShowRetry == true, "Expected \(error) to show retry")
        }
        
        for error in nonRetryableErrors {
            #expect(error.shouldShowRetry == false, "Expected \(error) to not show retry")
        }
    }
    
    @Test func testRecoverySuggestions() {
        let errorsWithSuggestions: [(WikipediaError, String)] = [
            (.networkUnavailable, "connection"),
            (.locationDenied, "Settings"),
            (.requestTimeout, "moments"),
            (.noResults, "different")
        ]
        
        for (error, expectedKeyword) in errorsWithSuggestions {
            let suggestion = error.recoverySuggestion
            #expect(suggestion != nil, "Error \(error) should have a recovery suggestion")
            #expect(suggestion!.localizedCaseInsensitiveContains(expectedKeyword),
                   "Suggestion for \(error) should contain '\(expectedKeyword)': \(suggestion!)")
        }
    }
    
    @Test func testErrorConversionFromURLError() {
        let urlErrors: [(URLError, WikipediaError)] = [
            (URLError(.notConnectedToInternet), .networkUnavailable),
            (URLError(.networkConnectionLost), .networkUnavailable),
            (URLError(.timedOut), .requestTimeout),
            (URLError(.badServerResponse), .invalidResponse)
        ]
        
        for (urlError, expectedError) in urlErrors {
            let converted = WikipediaError.from(urlError)
            #expect(converted == expectedError, "URLError \(urlError.code) should convert to \(expectedError)")
        }
    }
    
    @Test func testErrorConversionFromLocationError() {
        let locationErrors: [(LocationError, WikipediaError)] = [
            (.denied, .locationDenied),
            (.restricted, .locationRestricted),
            (.unableToDetermine, .locationUnavailable)
        ]
        
        for (locationError, expectedError) in locationErrors {
            let converted = WikipediaError.from(locationError)
            #expect(converted == expectedError, "LocationError \(locationError) should convert to \(expectedError)")
        }
    }
    
    @Test func testErrorEquality() {
        #expect(WikipediaError.networkUnavailable == WikipediaError.networkUnavailable)
        #expect(WikipediaError.serverError(500) == WikipediaError.serverError(500))
        #expect(WikipediaError.serverError(500) != WikipediaError.serverError(404))
        #expect(WikipediaError.unknown("test") == WikipediaError.unknown("test"))
        #expect(WikipediaError.unknown("test1") != WikipediaError.unknown("test2"))
    }
    
    @Test func testSpecificErrorMessages() {
        // Test specific error messages for key errors
        #expect(WikipediaError.networkUnavailable.errorDescription == "No internet connection available")
        #expect(WikipediaError.locationDenied.errorDescription == "Location access denied. Please enable in Settings.")
        #expect(WikipediaError.noResults.errorDescription == "No articles found")
        #expect(WikipediaError.requestTimeout.errorDescription == "Request timed out. Please try again.")
    }
    
    @Test func testServerErrorMessages() {
        let serverError404 = WikipediaError.serverError(404)
        let serverError500 = WikipediaError.serverError(500)
        
        #expect(serverError404.errorDescription == "Server error (404). Please try again.")
        #expect(serverError500.errorDescription == "Server error (500). Please try again.")
        #expect(serverError404.shouldShowRetry == true)
        #expect(serverError500.shouldShowRetry == true)
    }
    
    @Test func testLocationErrorSpecifics() {
        // Test location-specific errors have appropriate properties
        #expect(WikipediaError.locationDenied.shouldShowRetry == false)
        #expect(WikipediaError.locationRestricted.shouldShowRetry == false)
        #expect(WikipediaError.locationUnavailable.shouldShowRetry == true)
        
        // Test recovery suggestions
        let deniedSuggestion = WikipediaError.locationDenied.recoverySuggestion
        #expect(deniedSuggestion != nil)
        #expect(deniedSuggestion!.contains("Settings"))
        #expect(deniedSuggestion!.contains("Location Services"))
    }
    
    @Test func testNetworkErrorSpecifics() {
        // Test network-specific error properties
        #expect(WikipediaError.networkUnavailable.shouldShowRetry == true)
        #expect(WikipediaError.requestTimeout.shouldShowRetry == true)
        
        let networkSuggestion = WikipediaError.networkUnavailable.recoverySuggestion
        let timeoutSuggestion = WikipediaError.requestTimeout.recoverySuggestion
        
        #expect(networkSuggestion != nil)
        #expect(networkSuggestion!.contains("internet"))
        
        #expect(timeoutSuggestion != nil)
        #expect(timeoutSuggestion!.contains("again"))
    }
    
    @Test func testUnknownErrorHandling() {
        let customMessage = "Custom error message"
        let unknownError = WikipediaError.unknown(customMessage)
        
        #expect(unknownError.errorDescription == customMessage)
        #expect(unknownError.shouldShowRetry == false)
        #expect(unknownError.recoverySuggestion == "Please try again.")
    }
}
