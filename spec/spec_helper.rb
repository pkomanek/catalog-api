if ENV['CI']
  require 'simplecov'
  SimpleCov.start do
    track_files '{app,lib}/**/*.rb'
  end
end

ENV['RAILS_ENV'] ||= 'test'
ENV['APP_NAME'] ||= 'catalog'
ENV['PATH_PREFIX'] ||= 'api'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'webmock/rspec'

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
Dir[Insights::API::Common::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Insights::API::Common::Engine.root.join("lib/insights/api/common/rbac/*.rb")].each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.include FactoryBot::Syntax::Methods
  config.include UserHeaderSpecHelper

  config.include RequestSpecHelper, :type => :request

  # Version tracking for specs
  config.include V1Helper, :type => :v1
  config.include V1x1Helper, :type => :v1x1
  config.include V1InternalHelper, :type => :v1_internal
  # ------------------------ #

  config.include ServiceSpecHelper
  config.include TopologySpecHelper, :type => :topology
  config.include SourcesSpecHelper, :type => :sources
  config.include CurrentForwardableSpecHelper, :type => :current_forwardable

  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!
  config.include(Shoulda::Matchers::ActiveModel, :type => :model)
  config.include(Shoulda::Matchers::ActiveRecord, :type => :model)
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

end
FactoryBot::SyntaxRunner.send(:include, UserHeaderSpecHelper)
