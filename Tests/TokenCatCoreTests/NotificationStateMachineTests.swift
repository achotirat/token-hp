import TokenCatCore

func runNotificationStateMachineTests() {
    firstLowCrossingNotifiesOnce()
    recoveredProviderCanNotifyLowAgain()
    sleepingCrossingNotifiesExhausted()
    lowThenSleepingNotifiesBothTransitions()
}

private func firstLowCrossingNotifiesOnce() {
    var machine = NotificationStateMachine()

    expectNil(machine.record(provider: .claude, newCatState: .sitting))
    expectEqual(machine.record(provider: .claude, newCatState: .lyingDown), .low)
    expectNil(machine.record(provider: .claude, newCatState: .lyingDown))
}

private func recoveredProviderCanNotifyLowAgain() {
    var machine = NotificationStateMachine()

    _ = machine.record(provider: .claude, newCatState: .lyingDown)
    expectNil(machine.record(provider: .claude, newCatState: .sitting))
    expectEqual(machine.record(provider: .claude, newCatState: .lyingDown), .low)
}

private func sleepingCrossingNotifiesExhausted() {
    var machine = NotificationStateMachine()

    expectEqual(machine.record(provider: .codex, newCatState: .sleeping), .exhausted)
    expectNil(machine.record(provider: .codex, newCatState: .sleeping))
}

private func lowThenSleepingNotifiesBothTransitions() {
    var machine = NotificationStateMachine()

    expectEqual(machine.record(provider: .codex, newCatState: .lyingDown), .low)
    expectEqual(machine.record(provider: .codex, newCatState: .sleeping), .exhausted)
}
