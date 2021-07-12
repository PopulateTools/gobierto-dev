# frozen_string_literal: true

require "test_helper"

class SiteTest < ActiveSupport::TestCase
  def setup
    super
    @module_seeder_spy = Spy.on(GobiertoCommon::GobiertoSeeder::ModuleSeeder, :seed)
  end

  attr_reader :module_seeder_spy

  def first_call_arguments
    recipe_spy.calls.first.args
  end

  def madrid
    @madrid ||= sites(:madrid)
  end
  alias site madrid

  def santander
    @santander ||= sites(:santander)
  end

  def organization_site
    @organization_site ||= sites(:organization_wadus)
  end

  def draft_site
    @draft_site ||= sites(:santander)
  end

  def test_valid
    assert site.valid?
  end

  def test_root_path
    assert_equal "/presupuestos/elaboracion", site.root_path
  end

  # -- Initialization
  def test_admins_initialization
    site.admin_sites.delete_all

    assert_difference "site.admin_sites.size", 1 do
      site.send :initialize_admins
    end
  end

  # -- Configuration
  def test_configuration
    assert_kind_of SiteConfiguration, site.configuration
  end

  def test_password_protected?
    refute site.password_protected?
    assert draft_site.password_protected?
  end

  def test_place
    assert_kind_of INE::Places::Place, site.place
    assert site.place.present?
  end

  def test_place_when_organization_not_municipality
    assert_nil organization_site.place
  end

  def test_find_by_allowed_domain
    assert_equal site, Site.find_by_allowed_domain(site.domain)
    refute Site.find_by_allowed_domain("presupuestos." + ENV.fetch("HOST"))
    refute Site.find_by_allowed_domain("foo")
  end

  def test_site_attachments_collection_after_create
    site = Site.new title: "Transparencia", name: "Albacete", domain: "albacete.gobierto.test",
                    organization_name: "Albacete", organization_id: INE::Places::Place.find_by_slug("albacete").id

    site.configuration_data = {
      "links_markup" => %(<a href="http://madrid.es">Ayuntamiento de Madrid</a>),
      "logo" => "http://www.madrid.es/assets/images/logo-madrid.png",
      "modules" => %w(GobiertoBudgets GobiertoBudgetConsultations GobiertoPeople),
      "locale" => "en",
      "google_analytics_id" => "UA-000000-01"
    }
    site.save!

    assert_equal 1, site.collections.count
    collection = site.collections.first
    assert_equal "GobiertoAttachments::Attachment", collection.item_type
    assert_equal site, collection.container
  end

  def test_seeder_called_after_create
    site = Site.new title: "Transparencia", name: "Albacete", domain: "albacete.gobierto.test",
                    organization_name: "Albacete", organization_id: INE::Places::Place.find_by_slug("albacete").id

    site.configuration_data = {
      "links_markup" => %(<a href="http://madrid.es">Ayuntamiento de Madrid</a>),
      "logo" => "http://www.madrid.es/assets/images/logo-madrid.png",
      "modules" => %w(GobiertoBudgets GobiertoBudgetConsultations GobiertoPeople),
      "locale" => "en",
      "google_analytics_id" => "UA-000000-01"
    }
    site.save!

    assert module_seeder_spy.has_been_called?
    assert_equal ["GobiertoBudgets", site], module_seeder_spy.calls.first.args
  end

  def test_seeder_called_after_modules_updated
    configuration_data = santander.configuration_data
    configuration_data["modules"].push "GobiertoObservatory"
    santander.configuration_data = configuration_data
    santander.save!
    assert module_seeder_spy.has_been_called?
    assert_equal ["GobiertoObservatory", santander], module_seeder_spy.calls.first.args
  end

  def test_invalid_if_municipality_blank
    site.organization_id = nil
    site.save
    assert site.errors.messages[:base].one?
  end

  def test_date_filter_configured?
    conf = site.configuration

    refute site.date_filter_configured?

    # only start_date
    conf.raw_configuration_variables = <<-YAML
gobierto_people_default_filter_start_date: 2010-01-23
    YAML
    site.save

    assert site.date_filter_configured?

    # only end_date
    conf.raw_configuration_variables = <<-YAML
gobierto_people_default_filter_end_date: "2010-01-23"
    YAML
    site.save

    assert site.date_filter_configured?

    # both dates
    conf.raw_configuration_variables = <<-YAML
gobierto_people_default_filter_start_date: "2010-01-23"
gobierto_people_default_filter_end_date: "2010-01-23"
    YAML
    site.save

    assert site.date_filter_configured?

    # blank options
    conf.raw_configuration_variables = <<-YAML
gobierto_people_default_filter_start_date: ""
gobierto_people_default_filter_end_date:
    YAML
    site.save

    refute site.date_filter_configured?
  end

end
