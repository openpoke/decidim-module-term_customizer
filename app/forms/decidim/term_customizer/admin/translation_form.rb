# frozen_string_literal: true

module Decidim
  module TermCustomizer
    module Admin
      class TranslationForm < Decidim::Form
        include TranslatableAttributes

        mimic :translation

        delegate :translation_set, to: :context, prefix: false, allow_nil: true

        attribute :key, String
        translatable_attribute :value, String

        SEGMENT_FORMAT = %r{\A[A-Za-z0-9_/?-]+\z}

        validates :key, presence: true
        validates :value, translatable_presence: true
        validate :key_uniqueness
        validate :key_format, unless: -> { key.blank? }
        validate :key_hierarchy_uniqueness, unless: -> { key.blank? }

        def key_format
          return if key.split(".", -1).all? { |segment| segment.match?(SEGMENT_FORMAT) }

          errors.add(:key, :invalid)
        end

        def map_model(model)
          self.value = Decidim::TermCustomizer::Translation.where(
            translation_set: model.translation_set,
            key: model.key
          ).to_h do |translation|
            [translation.locale, translation.value]
          end
        end

        def key_uniqueness
          errors.add(:key, :taken) if translation_set && translation_set.translations.where(
            locale: I18n.locale,
            key:
          ).where.not(id:).exists?
        end

        def key_hierarchy_uniqueness
          return unless translation_set

          scope = translation_set.translations.where(locale: I18n.locale).where.not(id:)
          key_parts = key.split(".")
          ancestors = key_parts.each_index.map { |index| key_parts[0..index].join(".") }[0...-1]
          escaped_key = ActiveRecord::Base.sanitize_sql_like(key)

          has_ancestor = ancestors.any? && scope.exists?(key: ancestors)
          has_descendant = scope.exists?(["key LIKE ?", "#{escaped_key}.%"])

          errors.add(:key, :invalid) if has_ancestor || has_descendant
        end
      end
    end
  end
end
