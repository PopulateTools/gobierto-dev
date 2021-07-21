# frozen_string_literal: true

module GobiertoPlans
  class IndicatorDataDecorator < BaseDecorator

    attr_reader :plan, :collection

    def initialize(plan)
      @plan = plan
      @collection = plan.indicators
      @columns = 0
    end

    def csv
      lines = []
      CSV.generate do |csv|
        collection.each do |item|
          lines.concat(csv_row(item))
        end
        # need iterate again because header length is dynamic
        csv << csv_header
        lines.each do |line|
          csv << line.concat(Array.new(csv_header.size - line.size, nil))
        end
      end.force_encoding('utf-8')
    end

    private

    def csv_header
      header = %w(Node.Title Node.external_id custom_field)
      1.upto(@columns) do |index|
        header << "col_#{index}"
      end
      header
    end

    def values_keeping_order(object,record)
      attributes_in_order = object.custom_field.options.dig("configuration","plugin_configuration","columns").map { |r| r["id"] }
      attributes_in_order.map do |key|
        record[key]
      end
    end

    def csv_row(object)
      current_columns = object.payload[object.custom_field.uid.to_s].first&.size || 0
      @columns = current_columns if current_columns > @columns
      values = object.payload[object.custom_field.uid.to_s].map do |record|
        values_keeping_order(object,record)
      end

      values.map do |value|
        [
          plan.title_translations["en"],
          object.item.external_id,        # N+1 because it is polymorphic
          object.custom_field.uid
        ].concat(value)
      end
    end

  end
end
