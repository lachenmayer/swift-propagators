//
//  Cell.swift
//  Propagators
//
//  Created by Harry Lachenmayer on 20/10/2024.
//

public actor Cell<Content> where Content: Equatable {
  let name: String
  public private(set) var content: Content?
  private var neighbors: Set<Propagator> = []
  private let scheduler: Scheduler
  private let merge: @Sendable (Content?, Content?) throws -> Content?

  init(
    scheduler: Scheduler,
    name: String,
    initialContent: Content? = nil,
    merge: @escaping MergeFunction<Content>
  ) {
    self.scheduler = scheduler
    self.name = name
    self.content = initialContent
    self.merge = handleIncompleteValues(merge)
  }

  public func addContent(_ increment: Content?) async throws(Inconsistency) {
    do {
      let newContent = try merge(content, increment)
      if newContent == content { return }
      content = newContent
      await scheduler.alert(propagators: neighbors)
    } catch {
      throw Inconsistency(
        cell: name,
        content: "\(String(describing: content))",
        increment: "\(String(describing: increment))",
        mergeError: "\(error)"
      )
    }
  }

  func addNeighbor(_ propagator: Propagator) {
    neighbors.insert(propagator)
  }
}

public struct Inconsistency: Error, CustomStringConvertible {
  let cell: String
  let content: String
  let increment: String
  let mergeError: String

  public var description: String {
    "Cell '\(cell)' encountered an inconsistency:\nContent: \(content)\nIncrement: \(increment)\nMerge error: \(mergeError)"
  }
}

public struct AnyCell: Sendable {
  private let addNeighbor_: @Sendable (Propagator) async -> Void

  public init<Content: Equatable>(_ cell: Cell<Content>) {
    addNeighbor_ = { propagator in await cell.addNeighbor(propagator) }
  }

  public func addNeighbor(_ propagator: Propagator) async {
    await addNeighbor_(propagator)
  }
}

extension Cell {
  public nonisolated func erase() -> AnyCell {
    AnyCell(self)
  }
}

@Sendable private func handleIncompleteValues<Content: Equatable>(
  _ merge: @escaping MergeFunction<Content>
) -> @Sendable (Content?, Content?) throws -> Content? {
  return { content, increment in
    switch (content, increment) {
    case (.none, .none): return nil
    case let (.some(c), .none): return c
    case let (.none, .some(i)): return i
    case let (.some(c), .some(i)):
      if let merged = merge(c, i) {
        return merged
      } else {
        throw MergeError()
      }
    }
  }
}
