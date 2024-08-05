describe NavigationHelper, type: :helper do
  describe "#navigation_links_internal" do
    it "returns a link to the manuals page" do
      expect(navigation_links_internal).to include(a_hash_including(text: "Manuals", href: manuals_path))
    end

    it "toggles a what's new link based on whether it is before or after November 2023" do
      whats_new = a_hash_including(text: "What's new", href: whats_new_path)

      travel_to(Date.new(2023, 10, 31)) do
        expect(navigation_links_internal).to include(whats_new)
      end

      travel_to(Date.new(2023, 11, 1)) do
        expect(navigation_links_internal).not_to include(whats_new)
      end
    end

    it "sets the link to the manuals page as active when on the manuals index page" do
      request.path = manuals_path
      expect(navigation_links_internal).to include(a_hash_including(text: "Manuals", active: true))
    end

    it "sets the link to the manuals page as active when on a manual's view page" do
      manual = FactoryBot.build_stubbed(:manual)
      request.path = manual_path(manual)
      expect(navigation_links_internal).to include(a_hash_including(text: "Manuals", active: true))
    end
  end

  describe "#navigation_links_auth" do
    let(:current_user) { User.create!(name: "John Doe") }

    it "returns a list of auth links" do
      expect(navigation_links_auth).to include(
        a_hash_including(text: "John Doe", href: Plek.external_url_for("signon")),
      )
      expect(navigation_links_auth).to include(
        a_hash_including(text: "Log out", href: gds_sign_out_path),
      )
    end
  end
end
