# frozen_string_literal: true

module Decidim
  module TermCustomizer
    class TranslationDirectory
      attr_reader :locale

      def initialize(locale)
        @locale = locale.to_sym
      end

      def backend
        @backend ||= original_backend
      end

      def translations
        @translations ||= TranslationStore.new(backend_translations)
      end

      # as additional language might not be complete, we also search in the primary language translations to ensure full coverage
      # Note we assume English is the primary language in Decidim, which won't be changing anytime soon
      def primary_terms
        @primary_terms ||= TranslationStore.new(all_translations[:en])
      end

      def translations_search(search)
        translations_by_key(search)
          .merge(primary_terms.by_term(search))
          .merge(translations_by_term(search))
      end

      def translations_by_key(search)
        primary_terms.by_key(search)
      end

      def translations_by_term(search, case_sensitive: false)
        translations.by_term(search, case_sensitive:)
      end

      private

      def original_backend
        if I18n.backend.instance_of?(I18n::Backend::Chain)
          return I18n.backend.backends.find do |be|
            be.instance_of?(I18n::Backend::Simple)
          end
        end

        I18n.backend
      end

      def backend_translations
        all_translations[locale]
      end

      def all_translations
        backend.translations(do_init: true)
      end
    end
  end
end
