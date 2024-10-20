import Propagators
import Testing

@Test func add() async throws {
  let network = PropagationNetwork()
  let lhs = network.cell(2.0)
  let rhs = network.cell(3.0)
  let output: Cell<Double> = network.cell()
  await network.add(lhs: lhs, rhs: rhs, output: output)
  await network.run()
  #expect(await output.content == 5.0)
}

@Test func sum() async throws {
  let network = PropagationNetwork()
  let x: Cell<Double> = network.cell()
  let y = network.cell(3.0)
  let total = network.cell(5.0)
  await network.sum(lhs: x, rhs: y, total: total)
  await network.run()
  #expect(await x.content == 2.0)
}

@Test func fahrenheitCelsius() async throws {
  let network = PropagationNetwork()
  let c = network.cell(25.0)
  let f: Cell<Double> = network.cell()
  await network.fahrenheitCelsius(f: f, c: c)
  await network.run()
  let result = await f.content
  #expect(result == 77.0)
}

private extension PropagationNetwork {
  func fahrenheitCelsius(f: Cell<Double>, c: Cell<Double>) async {
    let thirtyTwo = self.cell(32.0)
    let five = self.cell(5.0)
    let nine = self.cell(9.0)
    let fMinus32: Cell<Double> = self.cell()
    let cBy9: Cell<Double> = self.cell()
    await self.sum(lhs: thirtyTwo, rhs: fMinus32, total: f)
    await self.product(lhs: fMinus32, rhs: five, total: cBy9)
    await self.product(lhs: c, rhs: nine, total: cBy9)
  }
}
