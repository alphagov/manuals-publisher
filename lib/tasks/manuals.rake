namespace :manuals do
  desc "Republishes all published manuals"
  task republish: :environment do
    registry = ManualServiceRegistry.new

    registry.list({}).call.select { |manual| manual.published? }.each do |manual|
      puts "Republishing #{manual.id} #{manual.title}"
      registry.republish(manual.id)
    end
  end
end
