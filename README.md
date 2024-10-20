# Propagators in Swift

This is an attempt to implement propagation networks, as described in [Radul 2009](https://dspace.mit.edu/handle/1721.1/54635), in Swift. This is purely for learning purposes, do not expect anything usable to come out of this repo.

A propagation network consists of independent, stateless machines called _propagators_ and stateful storage _cells_, which are connected together. Cells do not store values: instead, they accumulate information about values. This is the fundamental insight which makes propagation networks suitable for implementing constraint solving, logic programming, functional reactive programming, rule-based systems, type inference, and more.

It is an extremely powerful and general paradigm, which seems to be ideally suited for implementing multi-core and distributed programs. As opposed to traditional linear evaluation, propagators execute independently from one another, and do not impose a global ordering on time.

My goal is to translate the Scheme code in the paper to working Swift code. In theory, Swift's concurrency features are an ideal basis for this paradigm: Swift's actors allow us to safely express concurrent operations in a multi-threaded (and potentially even distributed!) setting. It should be easy to make the scheduler multi-threaded from day one, which is already an improvement over the paper!

The paper makes heavy use of Scheme's dynamic type system to implement extremely generic operators, for example propagation networks which can handle both numbers and intervals in the same network. For better or for worse, Swift's type system is too strict for implementing such extremely generic code. On the other hand, we'll be able to avoid a bunch of the boilerplate in the paper (such as the ["poor man's objects"](https://people.csail.mit.edu/gregs/ll1-discuss-archive-html/msg03277.html) needed for cells).

Once I have the base system working, my goal is to implement a functional reactive programming system based on the one mentioned in the paper.

## Further reading

- [Alexey Radul - Propagation networks: a flexible and expressive substrate for computation](https://dspace.mit.edu/handle/1721.1/54635) – the full paper.
- [Dennis Hansen - Holograph](https://www.holograph.so/), [Orion Reed - Scoped Propagators](https://www.orionreed.com/posts/scoped-propagators) – two very cool applications of propagators to canvas-based programming UIs.
- [David Thompson - Functional reactive user interfaces with propagators](https://dthompson.us/posts/functional-reactive-user-interfaces-with-propagators.html) – a Scheme FRP implementation with some interactive examples
- [George Wilson - An Intuition for Propagators - Compose Melbourne 2019](https://www.youtube.com/watch?v=nY1BCv3xn24) – great talk with an introduction to the mathematical theory behind propagators (bounded join semilattices)
- Edward Kmett - Propagators - YOW! 2016 ([part 1](https://www.youtube.com/watch?v=tETbivwzXBM), [part 2](https://www.youtube.com/watch?v=0igYOKcIWUs)) – much more hardcore deep dive into the theory behind propagators. Very "Haskell-y", in all senses of the word...

## Changelog

### 2024-10-20

Implemented the core system (up to Section 3 in the paper). The tests correspond to the examples given in the paper.

The paper takes some "poetic license" to avoid boilerplate: there are no references to the scheduler in any of the code snippets, and the scheduler is just a global mutable object in the paper. This obviously does not work for us: even if we did define a global scheduler constant, Swift Testing executes tests concurrently, so we'd end up scheduling a bunch of random stuff in tests.

Instead, I create an explicit `PropagationNetwork` type, which passes the scheduler around to individual cells and propagators. This also makes it possible to pass in different scheduler implementations in future, for example a test scheduler, or a serial / main thread scheduler for UI code. This is what you'd want in a 'production' library anyway.

We have to explicitly type each of the inputs to propagators, unlike the variadic procedures in the paper. For now, I have only implemented propagators with up to 2 inputs, but it should be trivial to extend this if needed. (In theory, Swift's "parameter packs" should make it possible to define well-typed variadic constructors, but I have so far only had bad experiences with this feature...)

The scheduler executes propagator alerts concurrently. I experimented with implementing a custom `TaskExecutor` to provide support for detecting "quiescence", but instead I just defined the scheduler as a separate actor which keeps "jobs" (async thunks) in a deque and schedules them concurrently using `withThrowingTaskGroup`.

In the paper, the scheduler `run` function has a return value – I'm not sure if this is possible (or even desirable). I need to check out the scheduler code in the paper more closely.

Unlike the paper, I have also added names to the cells, so it's possible to debug cells with contradictions.

The merge function can't be implemented as generically as in the paper, so instead we define a `Mergeable` protocol. The merge function can currently also be overridden for specific cells, but I'm not sure if this is necessary.

The paper doesn't explain how error handling is supposed to work, or if any of the errors  should be made recoverable in some way. For now, we just throw if any inconsistency is encountered. This will probably need to be refined.

Overall, I've been pleasantly surprised at how nicely this is to express in Swift so far. The FRP system will be an interesting challenge!

I need to properly read through [David Thompson - Functional reactive user interfaces with propagators](https://dthompson.us/posts/functional-reactive-user-interfaces-with-propagators.html), this seems really close to what I want to achieve (though also in Scheme).
