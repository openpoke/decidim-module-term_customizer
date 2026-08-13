# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module TermCustomizer
    module Admin
      module Filterable
        extend ActiveSupport::Concern

        included do
          include Decidim::Admin::Filterable

          private

          def base_query
            Decidim::TermCustomizer::TranslationSet.joins(:constraints).where(
              decidim_term_customizer_constraints: {
                decidim_organization_id: current_organization.id
              }
            ).distinct
          end

          def filtered_collection
            paginate(
              Decidim::TermCustomizer::TranslationSet
                .where(id: query.result.select(:id).reorder(nil))
                .order(translated_name_order, id: :asc)
            )
          end

          def translated_name_order
            locales = [I18n.locale.to_s, current_organization.default_locale.to_s].uniq

            Arel::Nodes::NamedFunction.new(
              "COALESCE",
              locales.map { |locale| blank_as_null(translated_name(locale)) }
            )
          end

          def translated_name(locale)
            Arel::Nodes::InfixOperation.new(
              "->>",
              Decidim::TermCustomizer::TranslationSet.arel_table[:name],
              Arel::Nodes.build_quoted(locale)
            )
          end

          def blank_as_null(node)
            Arel::Nodes::NamedFunction.new("NULLIF", [node, Arel::Nodes.build_quoted("")])
          end

          def search_field_predicate
            :search_text_or_translations_key_or_translations_value_cont
          end
        end
      end
    end
  end
end
