# frozen_string_literal: true

module GobiertoAdmin
  class Permission::Global < GroupPermission
    default_scope -> { where(namespace: "global", resource_type: "global") }
  end
end
