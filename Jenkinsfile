#!/usr/bin/env groovy

REPOSITORY = 'manuals-publisher'

def runTests() {
  echo 'Running tests'
  sh("TEST_COVERAGE=true bundle exec rake")
}

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'

    stage('Checkout') {
      checkout scm
    }

    stage("rubylinter") {
      govuk.rubyLinter("app bin config features Gemfile lib spec")
    }

    stage('Tests') {
      runTests()
    }
}
