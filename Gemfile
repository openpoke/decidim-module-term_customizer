# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

# Inside the development app, the relative require has to be one level up, as
# the Gemfile is copied to the development_app folder (almost) as is.
base_path = ""
base_path = "../" if File.basename(__dir__) == "development_app"
require_relative "#{base_path}lib/decidim/term_customizer/version"

DECIDIM_VERSION = Decidim::TermCustomizer::DECIDIM_VERSION

gem "decidim", DECIDIM_VERSION
gem "decidim-term_customizer", path: "."

gem "bootsnap", "~> 1.4"
gem "puma", ">= 5.6.2"

gem "faker", "~> 3.2"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri
  gem "dalli", "~> 2.7", ">= 2.7.10" # For testing MemCacheStore
  gem "decidim-dev", DECIDIM_VERSION
  gem "decidim-participatory_processes", DECIDIM_VERSION
  gem "decidim-proposals", DECIDIM_VERSION

  gem "rubocop-performance", "~> 1.23.1"
end

group :development do
  gem "letter_opener_web"
  gem "rubocop-faker"
  gem "web-console", "~> 4.2"
end
