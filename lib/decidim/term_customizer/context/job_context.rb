# frozen_string_literal: true

module Decidim
  module TermCustomizer
    module Context
      class JobContext < Base
        # rubocop:disable Metrics/CyclomaticComplexity
        def resolve!
          # Figure out the organization and user through the job arguments if
          # passed for the job.
          user = nil
          data[:job].arguments.each do |arg|
            @organization ||= organization_from_argument(arg)
            @space ||= space_from_argument(arg)
            @component ||= component_from_argument(arg)
            user ||= find_object_by_class(arg, Decidim::User)
          end

          # In case a component was found, define the space as the component
          # space to avoid any conflicts.
          @space = component.participatory_space if component

          # In case a space was found, define the organization as the space
          # organization to avoid any conflicts.
          @organization = space.organization if space

          # In case an organization could not be resolved any other way, check
          # it through the user (if the user was passed).
          @organization ||= user.organization if user
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        protected

        def organization_from_argument(arg)
          org = find_object_by_class(arg, Decidim::Organization)

          org || find_value_by_method(arg, :organization)
        end

        def space_from_argument(arg)
          space = find_object_by_class(arg, Decidim::Participable)

          space || find_value_by_method(arg, :participatory_space)
        end

        def component_from_argument(arg)
          component = find_object_by_class(arg, Decidim::Component)
          return component if component
          return find_value_by_method(arg, :component) if arg.respond_to?(:component)

          if defined?(Decidim::Forms::Questionnaire)
            component = find_questionnaire_component(arg)
            return component if component
          end

          nil
        end

        def find_questionnaire_component(arg)
          questionnaire_component = find_object_by_class(arg, Decidim::Forms::Questionnaire)&.questionnaire_for
          return questionnaire_component if questionnaire_component.is_a?(Decidim::Component)
          return questionnaire_component.component if questionnaire_component.respond_to?(:component)

          nil
        end

        def find_object_by_class(obj, klass, seen = {})
          return obj if obj.is_a?(klass)
          return nil if obj.nil?

          object_id = obj.__id__
          return nil if seen[object_id]

          seen[object_id] = true
          return find_object_by_class(obj.values, klass, seen) if obj.respond_to?(:values)

          if obj.respond_to?(:each)
            obj.each do |item|
              found = find_object_by_class(item, klass, seen)
              return found if found
            end
          end

          nil
        end

        def find_value_by_method(obj, method, seen = {})
          object_id = obj.__id__
          return nil if seen[object_id]

          seen[object_id] = true
          return obj.send(method) if obj.respond_to?(method)

          return find_value_by_method(obj.values, method, seen) if obj.respond_to?(:values)

          if obj.respond_to?(:each)
            obj.each do |item|
              found = find_value_by_method(item, method, seen)
              return found if found
            end
          end

          nil
        end
      end
    end
  end
end
