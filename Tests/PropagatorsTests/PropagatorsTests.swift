import Testing
@testable import Propagators

@Test func add() async throws {
  let lhs = Cell(2.0)
  let rhs = Cell(3.0)
  let output = Cell<Double>()
  await Propagator.add(lhs: lhs, rhs: rhs, output: output)
  await scheduler.run()
  #expect(await output.content == 5.0)
}
