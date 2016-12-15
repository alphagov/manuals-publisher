RSpec::Matchers.define :all_of do |*expected_matchers|
  match do |actual|
    expected_matchers.all? { |matcher| matcher === actual }
  end
end
