When(/^I withdraw the CMA case$/) do
  withdraw_cma_case(@document_title)
end

Then(/^the CMA case should be withdrawn$/) do
  check_document_is_withdrawn(@slug, @document_title)
end

Then(/^the CMA case should be withdrawn with a new draft$/) do
  check_document_is_withdrawn(@slug, @document_title)
  check_document_state(:cma_case, @document_title, "withdrawn with new draft")
end
