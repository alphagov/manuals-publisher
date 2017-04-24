# Manuals publisher

Manuals Publisher is a Ruby on Rails content management application for the 'manuals' format.
The manuals format is currently in a rendered phase of migration, so content is stored in a local
datastore but also drafted and published through the publishing-pipeline via the [Publishing API](https://github.com/alphagov/publishing-api).

This is the renamed repository of the original Specialist
Publisher. Specialist Publisher has been divided into two publishing
applications to accommodate Specialist Documents and Manuals
separately.  _Specialist Document_ or _Finders_ publishing now lives
at https://github.com/alphagov/specialist-publisher

## Purpose

Publishing app for manuals.

## Nomenclature

* Manual: Grouped Documents published as a number of sections inside a parent document

### Live examples of manuals

* [The Highway Code](https://www.gov.uk/guidance/the-highway-code)
* [Style guide](https://www.gov.uk/guidance/style-guide)
* [Buying for schools](https://www.gov.uk/guidance/buying-for-schools)

## Dependencies

* [alphagov/static](http://github.com/alphagov/static): provides static assets (JS/CSS)
* [alphagov/asset-manager](http://github.com/alphagov/asset-manager): provides uploading for static files
* [alphagov/rummager](http://github.com/alphagov/rummager): allows documents to be indexed for searching in both Finders and site search
* [alphagov/publishing-api](http://github.com/alphagov/publishing-api): allows documents to be published to the Publishing queue

## Running the application

To run the application in development you will need at least one user in the application database.
In a rails console do:

```
User.create!(name: "My Name", email: "my.email@somedomain.com", permissions: ["gds_editor"], organisation_slug: "government-digital-service", organisation_content_id: "af07d5a5-df63-4ddc-9383-6a666845ebe9")
```

Note: This insert (and the app in general) doesn't work with recent versions of MongoDB. v3.0.12 works OK; v3.4.1 does NOT work due to a problem with the `:w => 1` option no longer being supported at the top level, i.e. outside the Write Concern options. [It looks as if](https://github.com/alphagov/manuals-publisher/pull/796#issuecomment-276379600) [v2.4.9 is currently being used in production](https://github.com/alphagov/govuk-puppet/blob/f3614e33bcf037b218e0b9e816f0994786b41efb/hieradata/common.yaml#L1256).

Then start the application:

```
$ ./startup.sh
```

If you are using the GDS development virtual machine then the application will be available on the host at http://manuals-publisher.dev.gov.uk/

## Running the test suite

```
$ bundle exec rake
```

Note: The `cucumber` rake task which is run as part of the `default` rake task does not work with `bundler` versions of 1.13.0 onwards. The following exception occurs: `cannot load such file -- active_model/translation (LoadError)`. The full stack trace is recorded [here](https://gist.github.com/floehopper/79341ba0205a7d95fe0cd8ca369f8551). Based on the fact that [the Ruby version is set to v2.1.2](https://github.com/alphagov/manuals-publisher/blob/3ad5909d64c0fbb9f17c3dfdb1bcebf14e2cf80f/.ruby-version), it looks as if the version of `bundler` [currently being used in production is v1.6.5](https://github.com/alphagov/govuk-puppet/blob/b1afe36fcde7a6880be8d9bc5f0295914d4a9aa4/modules/govuk_rbenv/manifests/all.pp#L23-L25).

## Application directory structure

Non standard Rails directories and what they're used for:

* `app/exporters`
  These export information to various GOV.UK APIs
  * `app/exporters/formatters`
    These are used by exporters to format information for transferring as JSON
* `app/models`
  Combination of Mongoid documents and Ruby objects for handling Documents and various behaviours
  * `app/models/builders`
    Ruby objects for building a new document by setting ID and subclasses for setting the document type, if needed
  * `app/models/validators`
    Not validators. Decorators for providing validation logic.
* `app/repositories`
  Provide interaction with the persistance layer (Mongoid)
* `app/services`
  Reusable classes for completing actions on documents
* `app/view_adapters`
  Provide classes which allow us to have Rails like form objects in views
* `app/workers`
  Classes for sidekiq workers. Currently the only worker in the App is for publishing Manuals as Manual publishing was timing out due to the large number of document objects inside a Manual


### Services

 Services do things such as previewing a document, creation, updating, showing, withdrawing, queueing. This replaces the normal Rails behaviour of completing these actions directly from a controller, instead we call a service registry.

## Deleting or removing draft manuals

### Deleting a draft manual

If a manual has been created in draft but never published it can be deleted using a rake task to delete draft manuals:

```
rake delete_draft_manual[manual-slug,manual-id]
```

This would need to be run using Jenkins on one of the backend boxes.
