import Propagators
import Testing

@Test func add() async throws {
  let network = PropagationNetwork()
  let lhs = network.cell("lhs", 2.0)
  let rhs = network.cell("rhs", 3.0)
  let output: Cell<Double> = network.cell("output")
  await network.add(lhs: lhs, rhs: rhs, output: output)
  try await network.run()
  #expect(await output.content == 5.0)
}

@Test func sum() async throws {
  let network = PropagationNetwork()
  let x: Cell<Double> = network.cell("x")
  let y = network.cell("y", 3.0)
  let total = network.cell("total", 5.0)
  await network.sum(lhs: x, rhs: y, total: total)
  try await network.run()
  #expect(await x.content == 2.0)
}

@Test func fahrenheitCelsius() async throws {
  let network = PropagationNetwork()
  let c = network.cell("celsius", 25.0)
  let f: Cell<Double> = network.cell("fahrenheit")
  await network.fahrenheitCelsius(f: f, c: c)
  try await network.run()
  let result = await f.content
  #expect(result == 77.0)
}

extension PropagationNetwork {
  fileprivate func fahrenheitCelsius(f: Cell<Double>, c: Cell<Double>) async {
    let thirtyTwo = self.cell("32", 32.0)
    let five = self.cell("5", 5.0)
    let nine = self.cell("9", 9.0)
    let fMinus32: Cell<Double> = self.cell("f-32")
    let cBy9: Cell<Double> = self.cell("c*9")
    await self.sum(lhs: thirtyTwo, rhs: fMinus32, total: f)
    await self.product(lhs: fMinus32, rhs: five, total: cBy9)
    await self.product(lhs: c, rhs: nine, total: cBy9)
  }
}

@Test func buildingHeight_fallTime() async throws {
  let network = PropagationNetwork()
  let fallTime: Cell<Interval> = network.cell("fallTime")
  let buildingHeight: Cell<Interval> = network.cell("buildingHeight")
  await network.fallDuration(fallTime: fallTime, buildingHeight: buildingHeight)
  try await fallTime.addContent(Interval(low: 2.9, high: 3.1))
  try await network.run()
  let result = await buildingHeight.content!
  #expect(abs(result.low - 41.163) < 0.01)
  #expect(abs(result.high - 47.243) < 0.01)
}

@Test func buildingHeight_fallTimeAndShadow() async throws {
  let network = PropagationNetwork()
  let buildingHeight: Cell<Interval> = network.cell("buildingHeight")

  let fallTime: Cell<Interval> = network.cell("fallTime", Interval(low: 2.9, high: 3.1))
  await network.fallDuration(fallTime: fallTime, buildingHeight: buildingHeight)

  let buildingShadow = network.cell("buildingShadow", Interval(low: 54.9, high: 55.1))
  let barometerHeight = network.cell("barometerHeight", Interval(low: 0.3, high: 0.32))
  let barometerShadow = network.cell("barometerShadow", Interval(low: 0.36, high: 0.37))
  await network.similarTriangles(
    barometerShadow: barometerShadow, barometerHeight: barometerHeight,
    buildingShadow: buildingShadow, buildingHeight: buildingHeight)

  try await network.run()

  let result = await buildingHeight.content!
  #expect(abs(result.low - 44.514) < 0.01)
  #expect(abs(result.high - 48.978) < 0.01)
}

extension PropagationNetwork {
  fileprivate func intervalCell(_ name: String, initialContent: Interval? = nil) -> Cell<Interval> {
    self.cell(name, initialContent, merge: { content, increment in
      let intersection = content.intersect(increment)
      if intersection.isEmpty { return nil }
      return intersection
    })
  }

  fileprivate func fallDuration(fallTime t: Cell<Interval>, buildingHeight h: Cell<Interval>) async
  {
    let g = self.cell("g", Interval(low: 9.789, high: 9.832))
    let oneHalf = self.cell("1/2", Interval(exact: 0.5))
    let t2: Cell<Interval> = self.cell("t^2")
    let gt2: Cell<Interval> = self.cell("gt^2")
    await self.quadratic(n: t, n2: t2)
    await self.product(lhs: g, rhs: t2, total: gt2)
    await self.product(lhs: oneHalf, rhs: gt2, total: h)
  }

  fileprivate func similarTriangles(
    barometerShadow s_ba: Cell<Interval>, barometerHeight h_ba: Cell<Interval>,
    buildingShadow s: Cell<Interval>, buildingHeight h: Cell<Interval>
  ) async {
    let ratio: Cell<Interval> = self.cell("ratio")
    await self.product(lhs: s_ba, rhs: ratio, total: h_ba)
    await self.product(lhs: s, rhs: ratio, total: h)
  }
}
