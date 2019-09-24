class AnotherForceUpdateBrokenManualPublished < Mongoid::Migration
  def self.up
    user = User.find_by(email: "oscar.wyatt@digital.cabinet-office.gov.uk")
    if user
      manual = Manual.find("99005789-d82b-4045-932b-8ad9752a80bc", user)
      if manual
        service = Manual::UpdateService.new(
          user: user,
          manual_id: manual.id,
          attributes: { state: "published" },
        )
        service.call
        # It is incorrectly using the old publish tasks which are all aborted so delete them before republishing
        manual.publish_tasks.each(&:delete)
        manual.publish
      end
    end
  end

  def self.down; end
end
