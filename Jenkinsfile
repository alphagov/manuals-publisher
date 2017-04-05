#!/usr/bin/env groovy

// TODO: Call govuk.rubyLinter("app bin config features Gemfile lib spec")
// TODO: RUn tests with TEST_COVERAGE env var set to `true`

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'
  govuk.buildProject()
}
