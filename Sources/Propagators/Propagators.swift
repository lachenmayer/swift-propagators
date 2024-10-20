// Propagators in Swift.

import Collections
import Foundation

typealias Job = @Sendable () async -> Void

actor Scheduler {
  private var jobs = Deque<Job>()

  func schedule(_ job: @escaping Job) {
    jobs.append(job)
  }

  func alert(propagator: Propagator) {
    schedule { await propagator.alert() }
  }

  func alert(propagators: some Collection<Propagator>) {
    for propagator in propagators {
      alert(propagator: propagator)
    }
  }

  func run() async {
    while !jobs.isEmpty {
      var currentJobs = jobs
      jobs.removeAll()
      await withTaskGroup(of: Void.self) { group in
        while let job = currentJobs.popFirst() {
          group.addTask { await job() }
        }
      }
    }
  }
}

let scheduler = Scheduler()

actor Propagator {
  static func make<Output: Sendable>(_ f: @escaping @Sendable () -> Output, output: Cell<Output>)
    async
  {
    await Propagator.make(neighbors: []) {
      let o = f()
      await output.addContent(o)
    }
  }

  static func make<Input: Sendable, Output: Sendable>(
    _ f: @escaping @Sendable (Input) -> Output,
    _ input: Cell<Input>,
    output: Cell<Output>
  ) async {
    await Propagator.make(neighbors: [input.erase()]) {
      let i = await input.content
      let o = i.map { f($0) }
      await output.addContent(o)
    }
  }

  static func make<I1: Sendable, I2: Sendable, Output: Sendable>(
    _ f: @escaping @Sendable (I1, I2) -> Output,
    _ input1: Cell<I1>,
    _ input2: Cell<I2>,
    output: Cell<Output>
  ) async {
    await Propagator.make(neighbors: [input1.erase(), input2.erase()]) {
      async let i1 = input1.content
      async let i2 = input2.content
      let (i1_, i2_) = await (i1, i2)
      guard let i1_, let i2_ else { return }
      let o = f(i1_, i2_)
      await output.addContent(o)
    }
  }

  static func make(neighbors: [AnyCell], alert: @escaping Job) async {
    let propagator = Propagator(alert)
    for neighbor in neighbors {
      await scheduler.schedule {
        await neighbor.addNeighbor(propagator)
      }
    }
    await scheduler.alert(propagator: propagator)
  }

  let alert: Job

  private init(_ alert: @escaping Job) {
    self.alert = alert
  }
}

extension Propagator {
  static func constant<Value: Sendable>(_ value: Value, cell: Cell<Value>) async {
    await Propagator.make({ value }, output: cell)
  }

  static func add(lhs: Cell<Double>, rhs: Cell<Double>, output: Cell<Double>) async {
    await Propagator.make({ lhs, rhs in lhs + rhs }, lhs, rhs, output: output)
  }

  static func subtract(lhs: Cell<Double>, rhs: Cell<Double>, output: Cell<Double>) async {
    await Propagator.make({ lhs, rhs in lhs - rhs }, lhs, rhs, output: output)
  }

  static func multiply(lhs: Cell<Double>, rhs: Cell<Double>, output: Cell<Double>) async {
    await Propagator.make({ lhs, rhs in lhs * rhs }, lhs, rhs, output: output)
  }

  static func divide(lhs: Cell<Double>, rhs: Cell<Double>, output: Cell<Double>) async {
    await Propagator.make({ lhs, rhs in lhs / rhs }, lhs, rhs, output: output)
  }
}

extension Propagator: Equatable, Hashable {
  nonisolated var id: ObjectIdentifier { ObjectIdentifier(self) }

  static func == (lhs: Propagator, rhs: Propagator) -> Bool {
    lhs.id == rhs.id
  }

  nonisolated func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

struct AnyCell: Sendable {
  private let addNeighbor_: @Sendable (Propagator) async -> Void

  init<Content: Equatable>(_ cell: Cell<Content>) {
    addNeighbor_ = { propagator in await cell.addNeighbor(propagator) }
  }

  func addNeighbor(_ propagator: Propagator) async {
    await addNeighbor_(propagator)
  }
}

extension Cell {
  nonisolated func erase() -> AnyCell {
    AnyCell(self)
  }
}

actor Cell<Content: Equatable> {
  private(set) var content: Content?
  private var neighbors: Set<Propagator> = []

  init(_ content: Content? = nil) {
    self.content = content
  }

  func addContent(_ newContent: Content?) async -> Result<(), Inconsistency> {
    guard let newContent else {
      return Result.success(())
    }
    if let content {
      if newContent == content {
        return Result.success(())
      } else {
        return Result.failure(Inconsistency(message: "\(newContent) != \(content)"))
      }
    }
    content = newContent
    await scheduler.alert(propagators: neighbors)
    return Result.success(())
  }

  func addNeighbor(_ propagator: Propagator) {
    neighbors.insert(propagator)
  }
}

struct Inconsistency: Error {
  let message: String
}
