// Propagators in Swift.

import Collections
import Foundation

public actor Scheduler {
  public typealias Job = @Sendable () async -> Void

  private var jobs = Deque<Job>()

  public init() {}

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

public actor Propagator {
  let alert: Scheduler.Job

  init(_ alert: @escaping Scheduler.Job) {
    self.alert = alert
  }
}

extension Propagator: Equatable, Hashable {
  nonisolated var id: ObjectIdentifier { ObjectIdentifier(self) }

  public static func == (lhs: Propagator, rhs: Propagator) -> Bool {
    lhs.id == rhs.id
  }

  public nonisolated func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

public struct PropagationNetwork {
  private let scheduler: Scheduler

  public init(scheduler: Scheduler = Scheduler()) {
    self.scheduler = scheduler
  }

  public func run() async {
    await scheduler.run()
  }

  public func cell<Value>(_ initialValue: Value? = nil) -> Cell<Value>
  where Value: Equatable, Value: Sendable {
    Cell(scheduler: scheduler, content: initialValue)
  }

  public func propagator(neighbors: [AnyCell], alert: @escaping Scheduler.Job)
    async
  {
    let propagator = Propagator(alert)
    for neighbor in neighbors {
      await scheduler.schedule {
        await neighbor.addNeighbor(propagator)
      }
    }
    await scheduler.alert(propagator: propagator)
  }

  public func propagator<Output: Sendable>(
    _ f: @escaping @Sendable () -> Output, output: Cell<Output>
  ) async {
    await propagator(neighbors: []) {
      let o = f()
      await output.addContent(o)
    }
  }

  public func propagator<Input: Sendable, Output: Sendable>(
    _ f: @escaping @Sendable (Input) -> Output,
    _ input: Cell<Input>,
    output: Cell<Output>
  ) async {
    await propagator(neighbors: [input.erase()]) {
      let i = await input.content
      let o = i.map { f($0) }
      await output.addContent(o)
    }
  }

  public func propagator<I1: Sendable, I2: Sendable, Output: Sendable>(
    _ f: @escaping @Sendable (I1, I2) -> Output,
    _ input1: Cell<I1>,
    _ input2: Cell<I2>,
    output: Cell<Output>
  ) async {
    await propagator(neighbors: [input1.erase(), input2.erase()]) {
      async let i1 = input1.content
      async let i2 = input2.content
      let (i1_, i2_) = await (i1, i2)
      guard let i1_, let i2_ else { return }
      let o = f(i1_, i2_)
      await output.addContent(o)
    }
  }

  public func constant<Value: Sendable>(_ value: Value, cell: Cell<Value>) async {
    await propagator({ value }, output: cell)
  }

  // Math

  public func add(lhs: Cell<Double>, rhs: Cell<Double>, output: Cell<Double>) async {
    await propagator({ lhs, rhs in lhs + rhs }, lhs, rhs, output: output)
  }

  public func subtract(lhs: Cell<Double>, rhs: Cell<Double>, output: Cell<Double>) async {
    await propagator({ lhs, rhs in lhs - rhs }, lhs, rhs, output: output)
  }

  public func multiply(lhs: Cell<Double>, rhs: Cell<Double>, output: Cell<Double>) async {
    await propagator({ lhs, rhs in lhs * rhs }, lhs, rhs, output: output)
  }

  public func divide(lhs: Cell<Double>, rhs: Cell<Double>, output: Cell<Double>) async {
    await propagator({ lhs, rhs in lhs / rhs }, lhs, rhs, output: output)
  }

  public func sum(lhs: Cell<Double>, rhs: Cell<Double>, total: Cell<Double>) async {
    await add(lhs: lhs, rhs: rhs, output: total)
    await subtract(lhs: total, rhs: lhs, output: rhs)
    await subtract(lhs: total, rhs: rhs, output: lhs)
  }

  public func product(lhs: Cell<Double>, rhs: Cell<Double>, total: Cell<Double>) async {
    await multiply(lhs: lhs, rhs: rhs, output: total)
    await divide(lhs: total, rhs: lhs, output: rhs)
    await divide(lhs: total, rhs: rhs, output: lhs)
  }
}

public actor Cell<Content: Equatable> {
  private let scheduler: Scheduler
  public private(set) var content: Content?
  private var neighbors: Set<Propagator> = []

  init(scheduler: Scheduler, content: Content? = nil) {
    self.scheduler = scheduler
    self.content = content
  }

  public func addContent(_ newContent: Content?) async -> Result<(), Inconsistency> {
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

public struct Inconsistency: Error {
  let message: String
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
