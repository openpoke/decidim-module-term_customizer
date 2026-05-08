# frozen_string_literal: true

require "spec_helper"

module Decidim
  module TermCustomizer
    module Admin
      describe TranslationForm do
        subject { form }

        let(:organization) { create(:organization) }
        let(:translation_set) { create(:translation_set, organization:) }
        let(:key) { "translation.key" }
        let(:locale) { I18n.locale }
        let(:value) { Decidim::Faker::Localized.sentence(word_count: 3) }
        let(:params) { { key:, value: } }

        let(:form) do
          described_class.from_params(params).with_context(
            current_organization: organization,
            translation_set:
          )
        end

        context "when everything is OK" do
          it { is_expected.to be_valid }
        end

        context "when updating an existing translation without changing the key" do
          let(:translation) { create(:translation, key:, translation_set:) }
          let(:params) { { id: translation.id, key:, value: } }

          it { is_expected.to be_valid }
        end

        context "when key has an existing parent key" do
          let(:key) { "custom.pae.services.1" }

          before do
            create(:translation, translation_set:, locale:, key: "custom.pae.services")
          end

          it { is_expected.not_to be_valid }
        end

        context "when key has an existing child key" do
          let(:key) { "custom.pae.services" }

          before do
            create(:translation, translation_set:, locale:, key: "custom.pae.services.1")
          end

          it { is_expected.not_to be_valid }
        end

        context "when conflicting key exists in another locale" do
          let(:key) { "custom.pae.services" }

          before do
            create(:translation, translation_set:, locale: :fi, key: "custom.pae.services.1")
          end

          it { is_expected.to be_valid }
        end

        it_behaves_like "translation validatable"
      end
    end
  end
end
