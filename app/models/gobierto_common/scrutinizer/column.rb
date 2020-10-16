# frozen_string_literal: true

module GobiertoCommon
  module Scrutinizer
    class Column

      attr_reader :original_name, :db_name, :type

      def initialize(name)
        @original_name = name
        @db_name = name.parameterize(separator: "_").tr("-", "_")
        @type = nil
        @date_parser = nil
      end

      def detect_type(value)
        update_type(value)
      end

      def parsed_value(value)
        return if value.nil?

        case type
        when :date
          @date_parser.call(value)
        when :float
          Float(value)
        when :integer
          Integer(value)
        else
          value
        end
      end

      private

      def is_date?(value)
        @date_parser ||= if Date.strptime(value, "%m/%d/%Y").present?
                           ->(orig) { orig.blank? ? nil : Date.strptime(orig, "%m/%d/%Y") }
                         else
                           ->(orig) { orig.blank? ? nil : Date.parse(orig) }
                         end
        parsed_date = @date_parser.call(value)

        parsed_date.present? && parsed_date.year > 1900
      rescue ArgumentError
        false
      end

      def is_float?(value)
        return false if %w(, .).any { |c| value.count(c) > 1 }

        value = value.tr(",", ".")
        Float(value).present?
      rescue ArgumentError
        false
      end

      def is_integer?(value)
        Integer(value).present?
      rescue ArgumentError
        false
      end

      def update_type(value)
        return if value.nil? || @type.present? && (@type == :string || send("is_#{@type}?", value))

        @type = if @type.present?
                  @type == :integer && is_float?(value) ? :float : :string
                else
                  [:date, :integer, :float].find { |t| send("is_#{t}?", value) } || :string
                end
      end
    end
  end
end
