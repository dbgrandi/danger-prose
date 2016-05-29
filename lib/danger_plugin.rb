module Danger
  class DangerPlugin
      class Proselint < Plugin

        def self.plugin_instance(dangerfile)
          DangerProselint.new(dangerfile)
        end

      end
    end
  end
end