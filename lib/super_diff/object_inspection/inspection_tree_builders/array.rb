module SuperDiff
  module ObjectInspection
    module InspectionTreeBuilders
      class Array < Base
        def self.applies_to?(value)
          value.is_a?(::Array)
        end

        def call
          empty = -> { object.empty? }
          nonempty = -> { !object.empty? }

          InspectionTree.new do
            only_when empty do
              as_lines_when_rendering_to_lines { add_text "[]" }
            end

            only_when nonempty do
              as_lines_when_rendering_to_lines(collection_bookend: :open) do
                add_text "["
              end

              nested { |array| insert_array_inspection_of(array) }

              as_lines_when_rendering_to_lines(collection_bookend: :close) do
                add_text "]"
              end
            end
          end
        end
      end
    end
  end
end
