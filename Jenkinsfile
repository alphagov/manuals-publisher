#!/usr/bin/env groovy

REPOSITORY = 'manuals-publisher'
DEFAULT_SCHEMA_BRANCH = 'deployed-to-production'

def runTests() {
  echo 'Running tests'
  sh("TEST_COVERAGE=true bundle exec rake")
}

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'

  try {
    govuk.initializeParameters([
      'IS_SCHEMA_TEST': 'false',
      'SCHEMA_BRANCH': DEFAULT_SCHEMA_BRANCH,
    ])

    stage('Checkout') {
      checkout scm
    }

    stage("rubylinter") {
      govuk.rubyLinter("app bin config features Gemfile lib spec")
    }

    stage('Tests') {
      runTests()
    }

    if (env.BRANCH_NAME == 'master') {
      stage('Push release tag') {
        govuk.pushTag(REPOSITORY, BRANCH_NAME, 'release_' + BUILD_NUMBER)
      }

      stage('Deploy to Integration') {
        govuk.deployIntegration(REPOSITORY, BRANCH_NAME, 'release', 'deploy')
      }
    }
  } catch (e) {
    currentBuild.result = 'FAILED'
    step([$class: 'Mailer',
          notifyEveryUnstableBuild: true,
          recipients: 'govuk-ci-notifications@digital.cabinet-office.gov.uk',
          sendToIndividuals: true])
    throw e
  }
}
