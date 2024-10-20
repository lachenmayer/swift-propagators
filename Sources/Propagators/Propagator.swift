//
//  Propagator.swift
//  Propagators
//
//  Created by Harry Lachenmayer on 20/10/2024.
//

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
