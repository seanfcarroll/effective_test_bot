module EffectiveTestBot
  class Engine < ::Rails::Engine
    engine_name 'effective_test_bot'

    config.autoload_paths += Dir["#{config.root}/test/test_botable/**/"]
    config.autoload_paths += Dir["#{config.root}/test/concerns/**/"]
    config.autoload_paths += Dir["#{config.root}/test/support/**/"]

    # Set up our default configuration options.
    initializer "effective_test_bot.defaults", :before => :load_config_initializers do |app|
      # Set up our defaults, as per our initializer template
      eval File.read("#{config.root}/lib/generators/templates/effective_test_bot.rb")
    end

    initializer 'effective_test_bot.test_suite' do |app|
      if Rails.env.test?
        Rails.application.config.to_prepare do
          # test/support/
          ActionDispatch::IntegrationTest.include EffectiveTestBotAssertions
          ActionDispatch::IntegrationTest.include EffectiveTestBotFormHelper
          ActionDispatch::IntegrationTest.include EffectiveTestBotFormFiller
          ActionDispatch::IntegrationTest.include EffectiveTestBotLoginHelper
          ActionDispatch::IntegrationTest.include EffectiveTestBotMinitestHelper
          ActionDispatch::IntegrationTest.include EffectiveTestBotScreenshotsHelper
          ActionDispatch::IntegrationTest.include EffectiveTestBotTestHelper

          # test/test_botable/
          ActionDispatch::IntegrationTest.include BaseTest
          ActionDispatch::IntegrationTest.include CrudTest
          ActionDispatch::IntegrationTest.include DeviseTest
          ActionDispatch::IntegrationTest.include MemberTest
          ActionDispatch::IntegrationTest.include PageTest
          ActionDispatch::IntegrationTest.include RedirectTest
          ActionDispatch::IntegrationTest.include WizardTest

          # test/concerns/test_botable/
          ActionDispatch::IntegrationTest.include TestBotable::BaseDsl
          ActionDispatch::IntegrationTest.include TestBotable::CrudDsl
          ActionDispatch::IntegrationTest.include TestBotable::DeviseDsl
          ActionDispatch::IntegrationTest.include TestBotable::MemberDsl
          ActionDispatch::IntegrationTest.include TestBotable::PageDsl
          ActionDispatch::IntegrationTest.include TestBotable::RedirectDsl
          ActionDispatch::IntegrationTest.include TestBotable::WizardDsl
        end
      end
    end

    initializer 'effective_test_bot.middleware' do |app|
      if Rails.env.test?
        Rails.application.config.middleware.use EffectiveTestBot::Middleware
      end
    end

    initializer 'effective_test_bot.email_logger' do |app|
      if Rails.env.test?
        ActiveSupport.on_load :action_mailer do
          ActionMailer::Base.send :include, ::EffectiveTestBotMailerHelper

          if ActionMailer::Base.respond_to?(:after_action)
            ActionMailer::Base.send :after_action, :assign_test_bot_mailer_info
          else
            ActionMailer::Base.send :after_filter, :assign_test_bot_mailer_info
          end
        end
      end
    end

    initializer 'effective_test_bot.assign_assign_headers' do
      if Rails.env.test?
        ActiveSupport.on_load :action_controller do
          ActionController::Base.send :include, ::EffectiveTestBotControllerHelper

          if ActionController::Base.respond_to?(:before_action)
            ActionController::Base.send :before_action, :expires_now # Prevent 304 Not Modified caching
            ActionController::Base.send :after_action, :assign_test_bot_http_headers
          else
            ActionController::Base.send :before_filter, :expires_now # Prevent 304 Not Modified caching
            ActionController::Base.send :after_filter, :assign_test_bot_http_headers
          end

          ApplicationController.instance_exec do
            rescue_from ActionController::UnpermittedParameters do |exception|
              assign_test_bot_unpermitted_params_header(exception)
            end
          end
        end
      end
    end

  end
end
