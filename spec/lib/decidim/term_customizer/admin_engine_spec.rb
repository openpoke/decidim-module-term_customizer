# frozen_string_literal: true

require "spec_helper"

describe Decidim::TermCustomizer::AdminEngine do
  let(:context_class) do
    Class.new do
      def initialize(&block)
        @block = block
      end

      def call(*)
        instance_exec(*, &@block)
      end
    end
  end

  describe "#initialize decidim_term_customizer.admin_mount_routes" do
    subject(:route) do
      Decidim::Core::Engine.routes.routes.find do |r|
        r.name == "decidim_admin_term_customizer"
      end
    end

    before { Rails.application.reload_routes_unless_loaded }

    it "mounts the engine within the locale scope" do
      expect(route).not_to be_nil
      expect(route.path.spec.to_s).to eq("/:locale/admin/term_customizer")
    end
  end

  describe "#initialize decidim_term_customizer.admin_menu" do
    let(:menu) { double }
    let(:routes) { double }
    let(:path) { double }
    let(:organization) { double }
    let(:allowed_to_result) { double }

    it "adds the admin menu item" do
      expect(Decidim).to receive(:menu) do |name, &block|
        expect(name).to eq(:admin_menu)

        context = context_class.new(&block)
        allow(context).to receive_messages(decidim_admin_term_customizer: routes, current_organization: organization)
        allow(context).to receive(:allowed_to?).with(
          :update,
          :organization,
          organization:
        ).and_return(allowed_to_result)
        allow(routes).to receive(:translation_sets_path).and_return(path)
        expect(menu).to receive(:add_item).with(
          :term_customizer,
          "Term customizer",
          path,
          icon_name: "Decidim::TermCustomizer",
          position: 7.1,
          active: :inclusive,
          if: allowed_to_result
        )

        context.call(menu)
      end

      run_initializer("decidim_term_customizer.admin_menu")
    end
  end

  def run_initializer(initializer_name)
    config = described_class.initializers.find do |i|
      i.name == initializer_name
    end
    config.run
  end
end
