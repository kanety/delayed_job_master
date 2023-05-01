require_relative 'memory_checker'
require_relative 'signal_handler'
require_relative 'status_notifier'

[
  Delayed::Master::Plugins::MemoryChecker,
  Delayed::Master::Plugins::SignalHandler,
  Delayed::Master::Plugins::StatusNotifier
].each do |plugin|
  unless Delayed::Worker.plugins.include?(plugin)
    Delayed::Worker.plugins << plugin
  end
end
