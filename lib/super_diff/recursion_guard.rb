require "set"

module SuperDiff
  module RecursionGuard
    RECURSION_GUARD_KEY = "super_diff_recursion_guard_key".freeze
    PLACEHOLDER = "∙∙∙".freeze
    RECURSION_GUARD_COUNTER_KEY = "super_diff_recursion_guard_counter".freeze
    RECURSION_GUARD_COUNTER_MAX_OBJECTS_SEEN = 1000

    def self.guarding_recursion_of(*objects, &block)
      # This recursion counter is being added as a crude fix to the problem described in
      # https://github.com/mcmire/super_diff/issues/160
      # If that issue receives a more elegant solution, this can be removed from
      # the Tidelift version of the code.
      # Note: This is counting total objects seen, not necessarily recursed
      Thread.current[RECURSION_GUARD_COUNTER_KEY] ||= 0
      Thread.current[RECURSION_GUARD_COUNTER_KEY] = Thread.current[
        RECURSION_GUARD_COUNTER_KEY
      ] + 1

      already_seen_objects, first_seen_objects =
        objects.partition do |object|
          !SuperDiff.primitive?(object) &&
            (
              Thread.current[RECURSION_GUARD_COUNTER_KEY] >
                RECURSION_GUARD_COUNTER_MAX_OBJECTS_SEEN ||
                already_seen?(object)
            )
        end

      first_seen_objects.each do |object|
        already_seen_object_ids.add(object.object_id)
      end

      result =
        if block.arity > 0
          block.call(already_seen_objects.any?)
        else
          block.call
        end

      first_seen_objects.each do |object|
        already_seen_object_ids.delete(object.object_id)
      end

      result
    end

    def self.substituting_recursion_of(*objects)
      guarding_recursion_of(*objects) do |already_seen|
        if already_seen
          PLACEHOLDER
        else
          yield
        end
      end
    end

    def self.already_seen?(object)
      already_seen_object_ids.include?(object.object_id)
    end

    def self.already_seen_object_ids
      Thread.current[RECURSION_GUARD_KEY] ||= Set.new
    end
  end
end
