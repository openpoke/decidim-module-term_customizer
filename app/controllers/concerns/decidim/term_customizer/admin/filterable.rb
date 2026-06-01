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

          def search_field_predicate
            :search_text_or_translations_key_cont
          end
        end
      end
    end
  end
end
