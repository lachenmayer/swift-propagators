//
//  PropagationNetwork.swift
//  Propagators
//
//  Created by Harry Lachenmayer on 20/10/2024.
//

public struct PropagationNetwork {
  private let scheduler: Scheduler

  public init(scheduler: Scheduler = Scheduler()) {
    self.scheduler = scheduler
  }

  public func run() async throws {
    try await scheduler.run()
  }

  public func cell<Content>(
    _ name: String, _ initialContent: Content? = nil,
    merge: @escaping Cell<Content>.Merge = makeDefaultMerge()
  ) -> Cell<Content>
  where Content: Equatable, Content: Sendable {
    Cell(scheduler: scheduler, name: name, initialContent: initialContent)
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
      try await output.addContent(o)
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
      try await output.addContent(o)
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
      try await output.addContent(o)
    }
  }

  public func constant<Value: Sendable>(_ value: Value, cell: Cell<Value>) async {
    await propagator({ value }, output: cell)
  }
}
