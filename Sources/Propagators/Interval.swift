//
//  PropagationNetwork+Range.swift
//  Propagators
//
//  Created by Harry Lachenmayer on 20/10/2024.
//

import Foundation

public struct Interval: Equatable, Hashable, Sendable {
  public let low: Double
  public let high: Double

  public init(low: Double, high: Double) {
    self.low = low
    self.high = high
  }

  public init(exact: Double) {
    self.low = exact
    self.high = exact
  }

  public var isEmpty: Bool { low > high }
}

extension Interval: Mergeable {
  static public func merge(content: Interval, increment: Interval) -> Interval? {
    let intersected = content.intersect(increment)
    if intersected.isEmpty { return nil }
    return intersected
  }
}

public func * (lhs: Interval, rhs: Interval) -> Interval {
  Interval.lift((*), lhs, rhs)
}

public func / (lhs: Interval, rhs: Interval) -> Interval {
  lhs * Interval(low: 1.0 / rhs.high, high: 1.0 / rhs.low)
}

extension Interval {
  static func lift(_ f: (Double) -> Double, _ interval: Interval) -> Interval {
    Interval(low: f(interval.low), high: f(interval.high))
  }

  static func lift(_ f: (Double, Double) -> Double, _ lhs: Interval, _ rhs: Interval)
    -> Interval
  {
    Interval(low: f(lhs.low, rhs.low), high: f(lhs.high, rhs.high))
  }
}

extension Interval {
  public func intersect(_ other: Interval) -> Interval {
    Interval(low: max(self.low, other.low), high: min(self.high, other.high))
  }
}

extension PropagationNetwork {
  public func multiply(
    lhs: Cell<Interval>, rhs: Cell<Interval>, output: Cell<Interval>
  ) async {
    await propagator({ lhs, rhs in lhs * rhs }, lhs, rhs, output: output)
  }

  public func divide(
    lhs: Cell<Interval>, rhs: Cell<Interval>, output: Cell<Interval>
  ) async {
    await propagator({ lhs, rhs in lhs / rhs }, lhs, rhs, output: output)
  }

  public func product(
    lhs: Cell<Interval>, rhs: Cell<Interval>, total: Cell<Interval>
  ) async {
    await multiply(lhs: lhs, rhs: rhs, output: total)
    await divide(lhs: total, rhs: lhs, output: rhs)
    await divide(lhs: total, rhs: rhs, output: lhs)
  }

  public func square(n: Cell<Interval>, output: Cell<Interval>) async {
    await propagator({ n in n * n }, n, output: output)
  }

  public func sqrt(n: Cell<Interval>, output: Cell<Interval>) async {
    await propagator({ interval in Interval.lift(_math.sqrt, interval) }, n, output: output)
  }

  public func quadratic(n: Cell<Interval>, n2: Cell<Interval>) async {
    await square(n: n, output: n2)
    await sqrt(n: n2, output: n)
  }
}
