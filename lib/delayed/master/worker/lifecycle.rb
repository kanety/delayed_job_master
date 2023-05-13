# frozen_string_literal: true

events = Delayed::Lifecycle::EVENTS.dup.merge(
  thread: [:worker],
  scheduler_thread: [:worker],
  worker_thread: [:worker, :job]
)

Delayed::Lifecycle.send(:remove_const, :EVENTS)
Delayed::Lifecycle.const_set(:EVENTS, events)
