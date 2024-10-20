//
//  Math.swift
//  Propagators
//
//  Created by Harry Lachenmayer on 20/10/2024.
//

import Foundation

extension PropagationNetwork {
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

  public func square(n: Cell<Double>, output: Cell<Double>) async {
    await propagator({ n in n * n }, n, output: output)
  }

  public func sqrt(n: Cell<Double>, output: Cell<Double>) async {
    await propagator({ n in _math.sqrt(n) }, n, output: output)
  }

  public func quadratic(n: Cell<Double>, n2: Cell<Double>) async {
    await square(n: n, output: n2)
    await sqrt(n: n2, output: n)
  }
}
