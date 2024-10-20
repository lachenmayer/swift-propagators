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

extension PropagationNetwork {
  fileprivate func fahrenheitCelsius(f: Cell<Double>, c: Cell<Double>) async {
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

@Test func buildingHeight() async throws {
  let network = PropagationNetwork()
  let fallTime: Cell<Interval> = network.cell()
  let buildingHeight: Cell<Interval> = network.cell()
  await network.fallDuration(fallTime: fallTime, buildingHeight: buildingHeight)
  try await fallTime.addContent(Interval(low: 2.9, high: 3.1)).get()
  await network.run()
  let result = await buildingHeight.content
  #expect(abs(result!.low - 41.163) < 0.01)
  #expect(abs(result!.high - 47.243) < 0.01)
}

extension PropagationNetwork {
  fileprivate func fallDuration(fallTime t: Cell<Interval>, buildingHeight h: Cell<Interval>) async
  {
    let g = self.cell(Interval(low: 9.789, high: 9.832))
    let oneHalf = self.cell(Interval(exact: 0.5))
    let t2: Cell<Interval> = self.cell()
    let gt2: Cell<Interval> = self.cell()
    await self.quadratic(n: t, n2: t2)
    await self.product(lhs: g, rhs: t2, total: gt2)
    await self.product(lhs: oneHalf, rhs: gt2, total: h)
  }
}
