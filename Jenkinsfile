#!/usr/bin/env groovy

// TODO: Call govuk.rubyLinter("app bin config features Gemfile lib spec")

node('mongodb-2.4') {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'
  govuk.buildProject(
    sassLint: false,
    beforeTest: {
      govuk.setEnvar("TEST_COVERAGE", "true")
    }
  )
}
