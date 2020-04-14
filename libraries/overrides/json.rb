# frozen_string_literal: true

module ActiveSupport
  module ToJsonWithActiveSupportEncoder
    def to_json(options = nil)
      super(options)
    end
  end
end
