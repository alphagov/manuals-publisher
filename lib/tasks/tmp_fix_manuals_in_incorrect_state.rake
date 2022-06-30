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

  desc "Redirect manuals that have been deleted from Manuals Publisher"
  task redirect_deleted_manuals: :environment do
    deleted_section_redirects = [
      { content_id: "f217c208-504d-4f51-b548-13a70636e6c3", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/10-scheduling-and-the-inspection-team" },
      { content_id: "a713319f-0d0e-4b00-ac35-e2fb39988968", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/11-timeframe" },
      { content_id: "7d5f61aa-24d4-465e-a8ee-91f10815818a", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/12-preparing-for-an-inspection" },
      { content_id: "7c233636-8be7-4f97-bd9f-0e7bbd3cc130", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/13-the-on-site-inspection" },
      { content_id: "1858492b-6e63-4862-8250-4399228a4d62", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/14-making-requirements-and-recommendations" },
      { content_id: "2fdad307-bc56-4d3b-b248-fd2855c46256", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/15-inadequate-judgements-next-steps" },
      { content_id: "98844d92-14a6-4403-bfcd-542f9b6e6b2b", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/16-the-inspection-report" },
      { content_id: "336243a0-5555-4a0d-8d44-da345f4a7e4e", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/17-conduct-during-inspections" },
      { content_id: "c98fc6bb-5b78-4831-9b28-957e521661b8", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/18-concerns-or-complaints-about-an-inspection" },
      { content_id: "1cdef6eb-1d1c-43b3-b991-05c78396b045", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/19-interim-inspections" },
      { content_id: "c8dc69e1-9204-4b96-ae85-f96c37234d68", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/1-introduction" },
      { content_id: "504203f7-e35c-444d-9ac5-fbd51cf45891", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/20-monitoring-visits" },
      { content_id: "0cf9ba15-c28f-49c4-a7ac-9a59c80a15f1", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/21-checks-on-responsible-individuals" },
      { content_id: "a151654a-7596-4440-8431-5d25008060f2", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/22-inspections-where-no-children-are-living-in-the-home" },
      { content_id: "1a8cf252-6d9b-4434-be25-af5fdb4fc617", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/23-homes-where-there-is-no-registered-manager" },
      { content_id: "16107f24-cd78-4cd4-bab2-c650027422f2", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/24-inspecting-different-types-of-homes" },
      { content_id: "41d97a58-158d-44a5-8d5f-024ef92f2871", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/25-incomplete-inspections" },
      { content_id: "438f407f-6169-4644-9890-f47cf707defd", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/27-use-of-restraint" },
      { content_id: "af46699c-a357-4e1c-875b-6acd2785b6ba", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/28-homes-that-accommodate-young-adults" },
      { content_id: "ef999aff-676b-475f-9a30-50a08b321df1", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/29-safeguarding-and-child-protection-concerns" },
      { content_id: "462acd67-a1ef-45c6-9efe-135308f65610", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/2-the-inspection-principles" },
      { content_id: "372c43f3-e150-49d4-8f94-d6a67b6b5dbb", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/30-qualifications-of-registered-managers-and-staff-in-children-s-homes" },
      { content_id: "12d6136d-23ae-4062-a532-a3e0aea71538", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/30-use-of-personal-data" },
      { content_id: "6a799963-3847-4d08-8321-f4cac47b088a", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/3-the-focus-of-inspections" },
      { content_id: "dc39b98f-06a7-4861-a900-a7f8f3ed0f3d", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/4-how-inspectors-make-judgements-under-the-sccif" },
      { content_id: "40972271-248f-4265-9c92-94e2b0ec42dd", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/5-evaluation-criteria" },
      { content_id: "cc53a8af-643b-479c-934a-7031c21c8d0e", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/6-legal-context" },
      { content_id: "288bd6e5-73dc-45f4-8197-2d93c77c15f0", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/7-the-regulations-the-government-guide-and-the-sciff" },
      { content_id: "b4a852cd-b625-4d0d-b7d3-f680d8896ce0", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/8-types-of-inspection" },
      { content_id: "a62e496e-4b5a-4c90-9370-35097c5af8e4", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/9-notice" },
      { content_id: "e5745144-ae80-4bdf-bafe-8f21953cdc1b", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes/download-pdf-version" },
      { content_id: "72fd0186-928d-4ca5-98b2-409bf3919dae", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes" },
      { content_id: "7a7f09d0-dcb1-45c0-ad8a-6ab1580782ae", redirect: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes" },
    ]

    Services.publishing_api.unpublish(
      "7e144535-482a-4866-aac2-bdf3af3563c0",
      type: "redirect",
      redirects: [
        {
          path: "/guidance/social-care-common-inspection-framework-sccif-children-s-homes-including-secure-children-s-homes",
          type: "exact",
          destination: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes",
        },
        {
          path: "/guidance/social-care-common-inspection-framework-sccif-children-s-homes-including-secure-children-s-homes/updates",
          type: "exact",
          destination: "/guidance/social-care-common-inspection-framework-sccif-childrens-homes",
        },
      ],
      discard_drafts: true,
    )

    deleted_section_redirects.each do |route|
      Services.publishing_api.unpublish(
        route[:content_id],
        type: "redirect",
        alternative_path: (route[:redirect]).to_s,
        discard_drafts: true,
      )

      puts "Unpublished #{route[:content_id]} and redirected to #{route[:redirect]}"
    end
  end

  desc "Mark sections as published (instead of draft) which represents Publishing API and the live site"
  task tmp_mark_manuals_as_published: :environment do
    sections_which_should_be_published = %w[
      guidance/the-basic-payment-scheme-bps-rules-for-2016/business-structure
      guidance/the-basic-payment-scheme-bps-rules-for-2016/inspections
      guidance/the-basic-payment-scheme-bps-rules-for-2016/new-farmers-and-young-farmers
      guidance/the-basic-payment-scheme-bps-rules-for-2016/more-information-and-contact
      guidance/the-basic-payment-scheme-bps-rules-for-2016/key-dates-and-what-s-changed-for-2016
      guidance/the-basic-payment-scheme-bps-rules-for-2016/making-an-application
      guidance/the-basic-payment-scheme-bps-rules-for-2016/land
      guidance/the-basic-payment-scheme-bps-rules-for-2016/land-in-more-than-one-part-of-the-uk-cross-border
      guidance/the-basic-payment-scheme-bps-rules-for-2016/land-what-is-eligible-for-bps
      guidance/the-basic-payment-scheme-bps-rules-for-2016/entitlements
      guidance/the-basic-payment-scheme-bps-rules-for-2016/who-can-claim-bps
      guidance/the-basic-payment-scheme-bps-rules-for-2016/eligible-crops-2016
      guidance/the-basic-payment-scheme-bps-rules-for-2016/common-land-and-shared-grazing
    ]

    draft_paths = SectionEdition.in(slug: sections_which_should_be_published).where(state: "draft").pluck(:slug)

    return unless draft_paths.sort == sections_which_should_be_published.sort

    SectionEdition.in(slug: sections_which_should_be_published).where(state: "draft").update_all(state: "published")
  end
end
