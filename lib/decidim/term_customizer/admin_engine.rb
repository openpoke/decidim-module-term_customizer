# frozen_string_literal: true

module Decidim
  module TermCustomizer
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::TermCustomizer::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        resources :translation_sets, path: :sets, except: [:show] do
          member do
            post :duplicate
          end

          resources :translations, except: [:show] do
            collection do
              post :export
              get :import, action: :new_import
              post :import
              resource :translations_destroy, only: [:new, :destroy]
            end
          end
          resources :add_translations, only: [:index, :create] do
            collection do
              get :search
            end
          end
        end

        resources :caches, only: [:index] do
          collection do
            delete :clear
          end
        end

        root to: "translation_sets#index"
      end

      initializer "decidim_term_customizer.admin_mount_routes" do
        Decidim::Core::Engine.routes do
          mount Decidim::TermCustomizer::AdminEngine, at: "/admin/term_customizer", as: "decidim_admin_term_customizer"
        end
      end

      initializer "decidim_term_customizer.register_icons" do |_app|
        Decidim.icons.register(name: "Decidim::TermCustomizer", icon: "translate", category: "system", description: "Term Customizer", engine: :admin)
      end

      initializer "decidim_term_customizer.admin_menu" do
        Decidim.menu :admin_menu do |menu|
          menu.add_item(
            :term_customizer,
            I18n.t("menu.term_customizer", scope: "decidim.term_customizer"),
            decidim_admin_term_customizer.translation_sets_path,
            icon_name: "Decidim::TermCustomizer",
            position: 7.1,
            active: :inclusive,
            if: allowed_to?(:update, :organization, organization: current_organization)
          )
        end
      end

      initializer "decidim_term_customizer.cache_clear_fix" do
        # NOTE: remove this when Rails is updated to 7.0.8.8 or higher
        if Gem::Version.new(Rails.version) < Gem::Version.new('7.0.8.8')
          config.to_prepare do
            ActiveSupport::Cache::FileStore.class_eval do
              def file_path_key(path)
                fname = path[cache_path.to_s.size..-1].split(File::SEPARATOR, 4).last.delete(File::SEPARATOR)
                URI.decode_www_form_component(fname, Encoding::UTF_8)
              end
            end
          end
        end
      end
    end
  end
end
