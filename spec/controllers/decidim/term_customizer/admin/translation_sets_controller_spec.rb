# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TermCustomizer
    describe Admin::TranslationSetsController do
      include_context "with setup initializer"

      routes { Decidim::TermCustomizer::AdminEngine.routes }

      let(:organization) { create(:organization) }
      let(:other_organization) { create(:organization) }
      let(:user) { create(:user, :confirmed, :admin, organization:) }

      before do
        request.env["decidim.current_organization"] = organization
        sign_in user
      end

      describe "GET index" do
        render_views

        before do
          Bullet.add_safelist type: :counter_cache,
                              class_name: "Decidim::TermCustomizer::TranslationSet",
                              association: :translations
          create_list(:translation_set, 10, organization:)
          create_list(:translation_set, 10, organization: other_organization)
        end

        it "renders the index listing" do
          get :index
          expect(response).to have_http_status(:ok)
          expect(subject).to render_template(:index)
          expect(assigns(:sets).count).to eq(10)
        end

        it "shows the new translation set link" do
          get :index
          expect(response.body).to include(new_translation_set_path)
        end

        context "when filtering by translation value" do
          let(:matching_set) { create(:translation_set, organization:) }
          let(:non_matching_set) { create(:translation_set, organization:) }

          before do
            create(:translation, translation_set: matching_set, value: "Lorem ipsum dolor sit amet")
            create(:translation, translation_set: non_matching_set)
          end

          it "returns sets with translations matching the value" do
            get :index, params: {
              q: { search_text_or_translations_key_or_translations_value_cont: "Lorem ipsum dolor sit amet" }
            }
            expect(assigns(:sets)).to include(matching_set)
            expect(assigns(:sets)).not_to include(non_matching_set)
          end
        end

        context "when there are more sets than the page size" do
          before { create_list(:translation_set, 16, organization:) }

          it "shows the first page and links to the next one" do
            get :index
            expect(assigns(:sets).count).to eq(Decidim::Paginable::OPTIONS.first)
            expect(response.body).to include("page=2")
          end

          it "shows the remaining sets in the next page" do
            get :index, params: { page: 2 }
            expect(assigns(:sets).count).to eq(1)
          end
        end

        context "when the sets are not created in alphabetical order" do
          let!(:last_set) { create(:translation_set, organization:, name: { en: "Zzz set" }) }
          let!(:first_set) { create(:translation_set, organization:, name: { en: "Aaa set" }) }

          it "sorts them by their translated name" do
            get :index
            ids = assigns(:sets).map(&:id)
            expect(ids.index(first_set.id)).to be < ids.index(last_set.id)
          end
        end

        context "when a set has no name in the current locale" do
          let!(:localized_set) { create(:translation_set, organization:, name: { en: "Aaa set", ca: "Zzz conjunt" }) }
          let!(:fallback_set) { create(:translation_set, organization:, name: { en: "Bbb set" }) }

          it "sorts it by the name rendered in the list" do
            get :index, params: { locale: "ca" }
            ids = assigns(:sets).map(&:id)
            expect(ids.index(fallback_set.id)).to be < ids.index(localized_set.id)
          end
        end

        context "when two sets share the same name" do
          let!(:first_set) { create(:translation_set, organization:, name: { en: "Same name" }) }
          let!(:last_set) { create(:translation_set, organization:, name: { en: "Same name" }) }

          it "keeps them in a stable order" do
            get :index
            ids = assigns(:sets).map(&:id)
            expect(ids.select { |id| [first_set.id, last_set.id].include?(id) }).to eq([first_set.id, last_set.id])
          end
        end
      end

      describe "GET new" do
        render_views

        it "renders the empty form" do
          get :new
          expect(response).to have_http_status(:ok)
          expect(subject).to render_template(:new)
          expect(assigns(:subject_manifests)).to be_empty
        end

        context "when participatory space exists" do
          before do
            create(:participatory_process, organization:)
          end

          it "is available for selection" do
            expected = Decidim.participatory_space_manifests.select do |sm|
              sm.name == :participatory_processes
            end

            get :new
            expect(assigns(:subject_manifests)).to match_array(expected)
          end
        end
      end

      describe "POST create" do
        it "creates a translation set" do
          post :create, params: { name: { en: "Lorem ipsum dolor sit amet" } }

          expect(flash[:notice]).not_to be_empty
          expect(response).to have_http_status(:found)
        end
      end

      describe "GET edit" do
        let(:translation_set) { create(:translation_set, organization:) }

        it "renders the edit form" do
          get :edit, params: { id: translation_set.id }
          expect(response).to have_http_status(:ok)
          expect(subject).to render_template(:edit)
        end
      end

      describe "PUT update" do
        let(:translation_set) { create(:translation_set, organization:) }

        it "updates the translation set" do
          put :update, params: {
            id: translation_set.id,
            name: { en: "Lorem ipsum dolor sit amet" }
          }

          expect(flash[:notice]).not_to be_empty
          expect(response).to have_http_status(:found)
        end
      end

      describe "DELETE destroy" do
        let(:translation_set) { create(:translation_set, organization:) }

        it "destroys the translation set" do
          delete :destroy, params: { id: translation_set.id }

          expect(flash[:notice]).not_to be_empty
          expect(response).to have_http_status(:found)
        end
      end

      describe "POST duplicate" do
        let(:translation_set) { create(:translation_set, organization:) }

        it "duplicates a translation set" do
          post :duplicate, params: { id: translation_set.id }

          expect(flash[:notice]).not_to be_empty
          expect(response).to have_http_status(:found)
        end
      end
    end
  end
end
