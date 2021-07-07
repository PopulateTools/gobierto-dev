# frozen_string_literal: true

module BudgetsFactory

  extend ActiveSupport::Concern

  INDEXES = {
    forecast: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast,
    forecast_updated: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast_updated,
    executed: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed
  }

  class_methods do
    def default_amount
      123_456.789
    end

    def default_population
      100
    end

    def default_place
      INE::Places::Place.find_by_slug("madrid")
    end

    def default_organization_id
      default_place.id
    end

    def default_code
      "1"
    end

    def default_kind
      GobiertoData::GobiertoBudgets::EXPENSE
    end

    def default_area
      GobiertoData::GobiertoBudgets::ECONOMIC_AREA_NAME
    end

    def default_year
      Time.now.year
    end

    def base_data(params = {})
      place_attributes(params).merge(
        organization_id: params[:organization_id] || default_organization_id,
        year: params[:year] || default_year
      )
    end

    def place_attributes(params = {})
      place = params[:place] || default_place

      {
        ine_code: place.id,
        province_id: place.province_id,
        autonomy_id: place.province.autonomous_region_id
      }
    end
  end

  attr_accessor :client, :created_documents

  def initialize(params = {})
    self.client = GobiertoBudgets::SearchEngine.client
    elasticsearch_url = client.instance_variable_get(:@options)[:url]

#    unless (Rails.env.development? || Rails.env.test?) && elasticsearch_url.include?("localhost")
#      raise "ERROR: it's not safe to run a BudgetsFactory in #{Rails.env} pointing to #{elasticsearch_url}"
#    end

    indexes = if params[:indexes]
                params[:indexes].map { |index_alias| INDEXES[index_alias] }
              else
                INDEXES.values
              end
    params.delete(:indexes)

    documents = indexes.map { |index| build_document(index, params) }
    result = bulk(body: documents)

    self.created_documents = result["items"].map do |doc|
      doc["index"].slice("_index", "_type", "_id")
    end
  end

  def teardown
    bulk(body: teardown_body)
  end

  private

  def bulk(params = {})
    client.bulk(params.merge(refresh: true))
  end

  def teardown_body
    created_documents.map { |doc_summary| { delete: doc_summary } }
  end

end
