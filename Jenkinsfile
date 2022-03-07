#!/usr/bin/env groovy

library("govuk")

node("mongodb-2.4") {
  govuk.setEnvar("PUBLISHING_E2E_TESTS_COMMAND", "test-manuals-publisher")
  govuk.buildProject(
    beforeTest: {
      govuk.setEnvar("TEST_COVERAGE", "true")
    },
    publishingE2ETests: true,
    brakeman: true,
  )
}
