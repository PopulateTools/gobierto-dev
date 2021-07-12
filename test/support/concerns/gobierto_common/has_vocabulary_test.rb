# frozen_string_literal: true

module GobiertoCommon
  module HasVocabularyTest
    attr_reader :model, :vocabularies, :site_with_vocabularies, :site_without_vocabularies, :singular_vocabularies

    def setup_has_vocabulary_module(opts = {})
      @model ||= opts[:model]
      @vocabularies ||= opts[:vocabularies]
      @site_with_vocabularies ||= opts[:site_with_vocabularies]
      @site_without_vocabularies ||= opts[:site_without_vocabularies]
      @singular_vocabularies = @vocabularies.map { |v| v.to_s.singularize.to_sym }.sort
    end

    def site
      @site ||= sites(:madrid)
    end

    def new_instance
      @new_instance ||= model.new
    end

    def test_vocabularies_present
      assert model.respond_to? :vocabularies
      assert_equal singular_vocabularies, model.vocabularies.keys.sort
    end

    def test_association_attribute
      singular_vocabularies.each do |method|
        assert new_instance.respond_to? method
      end
    end

    def test_associations_are_terms
      singular_vocabularies.each do |method|
        not_empty = model.where.not(method => nil).first
        assert not_empty.send(method).is_a? GobiertoCommon::Term
      end
    end

    def test_associated_term_is_scoped_with_vocabulary
      singular_vocabularies.each do |method|
        not_empty = model.where.not(method => nil).first
        assert not_empty.send(method).present?

        setting_name = model.vocabularies[method]
        module_name = model.name.deconstantize
        not_empty.site.settings_for_module(module_name).send("#{ setting_name }=", nil)
        not_empty.site.settings_for_module(module_name).save
        not_empty.reload
        assert not_empty.send(method).blank?
      end
    end

  end
end
