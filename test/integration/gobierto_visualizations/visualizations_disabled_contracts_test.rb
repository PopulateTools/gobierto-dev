# frozen_string_literal: true

require "test_helper"

class GobiertoVisualizations::VisualizationsDisabledContractsTest < ActionDispatch::IntegrationTest
  def setup
    super
    @contracts_path = gobierto_visualizations_contracts_path

    ::GobiertoModuleSettings.create!({
      site_id: site.id,
      module_name: "GobiertoVisualizations",
      settings: settings
    })
  end

  def site
    @site ||= sites(:madrid)
  end

  def settings
    {
      "visualizations_config" => {
        "visualizations" => {
          "contracts" => {
            "enabled" => false,
            "data_urls" => { }
          }
        }
      }
    }
  end

  def test_disability
    with(site: site) do
      visit @contracts_path
      assert_equal 404, page.status_code
    end
  end

end
