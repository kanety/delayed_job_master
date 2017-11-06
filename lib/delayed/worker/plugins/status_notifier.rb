class Delayed::Plugins::StatusNotifier < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.around(:perform) do |worker, job, &block|
      title = $0
      $0 = "#{title} [BUSY]"
      ret = block.call
      $0 = title
      ret
    end
  end
end

Delayed::Worker.plugins << Delayed::Plugins::StatusNotifier
