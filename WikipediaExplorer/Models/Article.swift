import Foundation

public struct Article: Identifiable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let fullURL: URL?
    public let thumbnailURL: URL?
    public let geo: Geo?
}
