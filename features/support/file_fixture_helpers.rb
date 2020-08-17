module FileFixtureHelpers
  def fixture_filepath(filename)
    filepath = File.expand_path("../fixtures/#{filename}", File.dirname(__FILE__))
    raise "Fixture #{filename} not found" unless File.exist?(filepath)

    filepath
  end
end

RSpec.configuration.include FileFixtureHelpers, type: :feature
World(FileFixtureHelpers) if respond_to?(:World)
