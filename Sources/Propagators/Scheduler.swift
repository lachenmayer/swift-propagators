//
//  Scheduler.swift
//  Propagators
//
//  Created by Harry Lachenmayer on 20/10/2024.
//

import Collections

public actor Scheduler {
  public typealias Job = @Sendable () async throws -> Void

  private var jobs = Deque<Job>()

  public init() {}

  func schedule(_ job: @escaping Job) {
    jobs.append(job)
  }

  func alert(propagator: Propagator) {
    schedule { try await propagator.alert() }
  }

  func alert(propagators: some Collection<Propagator>) {
    for propagator in propagators {
      alert(propagator: propagator)
    }
  }

  func run() async throws {
    while !jobs.isEmpty {
      var currentJobs = jobs
      jobs.removeAll()
      try await withThrowingTaskGroup(of: Void.self) { group in
        while let job = currentJobs.popFirst() {
          group.addTask { try await job() }
        }
        try await group.waitForAll()
      }
    }
  }
}
