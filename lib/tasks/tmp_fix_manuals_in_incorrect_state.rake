namespace :tmp_fix_manuals_in_incorrect_state do
  desc "Redirect manuals that are incorrect state in Manuals Publisher"
  task redirect_withdrawn_manuals: :environment do
    manual_routes = [
      { base_path: "guidance/civil-procedure-rules-parts-41-to-60", redirect: "/guidance/the-civil-procedure-rules" },
      { base_path: "guidance/civil-procedure-rules-parts-61-to-80", redirect: "/guidance/the-civil-procedure-rules" },
    ]

    section_routes = [
      { base_path: "guidance/civil-procedure-rules-parts-41-to-60/part-41-damages", redirect: "/guidance/the-civil-procedure-rules/part-41-damages" },
      { base_path: "guidance/civil-procedure-rules-parts-61-to-80/part-61-admiralty-claims", redirect: "/guidance/the-civil-procedure-rules/part-61-admiralty-claims" },
    ]

    manual_routes.each do |route|
      manual = Manual.find_by_slug!(route[:base_path], User.gds_editor)

      Adapters.publishing.unpublish_and_redirect_manual_and_sections(
        manual, redirect: route[:redirect], include_sections: false, discard_drafts: true
      )

      puts "Unpublished #{route[:base_path]} and redirected to #{route[:redirect]}"
    end

    section_routes.each do |route|
      section_edition = SectionEdition.find_by(slug: route[:base_path])
      manual = Manual.find_by_slug!(route[:base_path].split("/")[0..1].join("/"), User.gds_editor)
      section = Section.find(manual, section_edition.section_uuid)

      Adapters.publishing.unpublish_section(
        section, redirect: route[:redirect], discard_drafts: true
      )

      puts "Unpublished #{route[:base_path]} and redirected to #{route[:redirect]}"
    end
  end
end
