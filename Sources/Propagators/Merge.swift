//
//  Merge.swift
//  Propagators
//
//  Created by Harry Lachenmayer on 20/10/2024.
//

public typealias MergeFunction<Content> = @Sendable (Content, Content) -> Content?

public protocol Mergeable {
  static func merge(content: Self, increment: Self) -> Self?
}

public enum Merge {
  @Sendable public static func equality<Content>() -> MergeFunction<Content>
  where Content: Equatable {
    { a, b in if a == b { a } else { nil } }
  }
}

struct MergeError: Error {}
