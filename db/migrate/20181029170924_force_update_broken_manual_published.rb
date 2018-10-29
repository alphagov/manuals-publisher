class ForceUpdateBrokenManualPublished < Mongoid::Migration
  def self.up
    user = User.find_by(email: "oscar.wyatt@digital.cabinet-office.gov.uk")
    if user
      manual = Manual.find("b59056ac-f7e9-4415-96b5-79cc5cfb0a76", user)
      if manual
        manual.editions.sort_by{|ed| ed.created_at}.last.update(state: "published")
      end
    end
  end

  def self.down
  end
end
