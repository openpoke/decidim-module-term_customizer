# frozen_string_literal: true

require "spec_helper"

describe "Decidim::TermCustomizer.loader" do
  describe ".loader" do
    it "is isolated per thread" do
      loader_org1 = double("loader_org1")
      loader_org2 = double("loader_org2")

      thread1_loader = nil
      thread2_loader = nil

      t1 = Thread.new do
        Decidim::TermCustomizer.loader = loader_org1
        sleep 0.05
        thread1_loader = Decidim::TermCustomizer.loader
      end

      t2 = Thread.new do
        sleep 0.02
        Decidim::TermCustomizer.loader = loader_org2
        thread2_loader = Decidim::TermCustomizer.loader
      end

      t1.join
      t2.join

      expect(thread1_loader).to eq(loader_org1)
      expect(thread2_loader).to eq(loader_org2)
    end
  end

  describe "Decidim::TermCustomizer::I18nBackend" do
    let(:backend) { Decidim::TermCustomizer::I18nBackend.new }

    let(:translations_org1) { { en: { decidim: { test_key: "Org 1 translation" } } } }
    let(:translations_org2) { { en: { decidim: { test_key: "Org 2 translation" } } } }

    it "does not bleed translations between concurrent threads" do
      loader_org1 = double("loader_org1", translations_hash: translations_org1)
      loader_org2 = double("loader_org2", translations_hash: translations_org2)

      result_thread1 = nil
      result_thread2 = nil

      t1 = Thread.new do
        Decidim::TermCustomizer.loader = loader_org1
        sleep 0.05
        result_thread1 = backend.translations
      end

      t2 = Thread.new do
        sleep 0.02
        Decidim::TermCustomizer.loader = loader_org2
        result_thread2 = backend.translations
      end

      t1.join
      t2.join

      expect(result_thread1).to eq(translations_org1)
      expect(result_thread2).to eq(translations_org2)
    end
  end
end
