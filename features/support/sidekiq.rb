require "govuk_sidekiq/testing"
Sidekiq::Testing.inline!

Before("@disable_background_processing") do
  Sidekiq::Testing.fake!
end

After("@disable_background_processing") do
  Sidekiq::Testing.inline!
end
