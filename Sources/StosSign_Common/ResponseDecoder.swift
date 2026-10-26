//
//  ResponseDecoder.swift
//  StosSign
//
//  Apple answers some endpoints with a property list and others with JSON, and the format has
//  changed over time. Decoding both keeps signing in working across those changes; when neither
//  parses, the caller reports the raw payload instead of a bare NSCocoaErrorDomain 3840.
//

import Foundation

public enum StosSignResponseDecoder {
    /// Decodes a response body as a property list, falling back to JSON.
    public static func dictionary(from data: Data) -> [String: Any]? {
        if let plist = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any] {
            return plist
        }
        if let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] {
            return json
        }
        return nil
    }

    /// Reads a binary field, which JSON carries as a base64 string.
    public static func data(_ value: Any?) -> Data? {
        if let data = value as? Data {
            return data
        }
        if let string = value as? String {
            return Data(base64Encoded: string)
        }
        return nil
    }

    /// A short, single line excerpt of a payload that could not be decoded, together with the
    /// HTTP status and content type when they are available.
    public static func describe(_ data: Data, response: URLResponse? = nil, limit: Int = 240) -> String {
        var parts: [String] = []
        if let http = response as? HTTPURLResponse {
            parts.append("HTTP \(http.statusCode)")
            if let contentType = http.value(forHTTPHeaderField: "Content-Type") {
                parts.append("Content-Type: \(contentType)")
            }
        }
        guard !data.isEmpty else {
            parts.append("<empty body>")
            return parts.joined(separator: " | ")
        }
        if let text = String(data: data.prefix(limit), encoding: .utf8) {
            let flattened = text
                .replacingOccurrences(of: "\r", with: " ")
                .replacingOccurrences(of: "\n", with: " ")
            parts.append(flattened)
        } else {
            parts.append("<\(data.count) bytes of binary data>")
        }
        return parts.joined(separator: " | ")
    }
}
