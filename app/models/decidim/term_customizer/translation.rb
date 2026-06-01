# frozen_string_literal: true

module Decidim
  module TermCustomizer
    class Translation < TermCustomizer::ApplicationRecord
      self.table_name = "decidim_term_customizer_translations"

      belongs_to :translation_set, class_name: "Decidim::TermCustomizer::TranslationSet"
      has_many :constraints, through: :translation_set

      validates :locale, presence: true
      validates :key, presence: true
      validates :key, format: { with: %r{\A([A-Za-z0-9_/?-]+\.)*[A-Za-z0-9_/?-]+\z} }, unless: -> { key.blank? }
      validates :key, uniqueness: { scope: [:translation_set, :locale] }, unless: -> { key.blank? }

      class << self
        def available_locales
          Translation.select("DISTINCT locale").to_a.map { |t| t.locale.to_sym }
        end
      end

      def self.ransackable_attributes(_auth_object = nil)
        %w(key)
      end
    end
  end
end
