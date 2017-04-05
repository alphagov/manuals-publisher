#!/usr/bin/env groovy

// TODO: Call govuk.rubyLinter("app bin config features Gemfile lib spec")

def runTests() {
  echo 'Running tests'
  sh("TEST_COVERAGE=true bundle exec rake")
}

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'

    stage('Tests') {
      runTests()
    }
}
