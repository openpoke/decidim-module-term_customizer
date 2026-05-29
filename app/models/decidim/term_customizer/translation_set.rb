# frozen_string_literal: true

module Decidim
  module TermCustomizer
    class TranslationSet < TermCustomizer::ApplicationRecord
      include Decidim::FilterableResource

      self.table_name = "decidim_term_customizer_translation_sets"

      has_many :translations,
               class_name: "Decidim::TermCustomizer::Translation",
               dependent: :destroy

      has_many :constraints,
               class_name: "Decidim::TermCustomizer::Constraint",
               dependent: :destroy

      # Create i18n ransackers for :name and :description.
      # Create the :search_text ransacker alias for searching from both of these.
      ransacker_i18n_multi :search_text, [:name]

      def self.ransackable_attributes(_auth_object = nil)
        %w(search_text)
      end

      def self.ransackable_associations(_auth_object = nil)
        []
      end
    end
  end
end
