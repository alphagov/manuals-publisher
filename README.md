# Manuals publisher

Manuals Publisher is a Ruby on Rails content management application for the 'manuals' format.
The manuals format is currently in a rendered phase of migration, so content is stored in a local
datastore but also drafted and published through the publishing-pipeline via the [Publishing API](https://github.com/alphagov/publishing-api).


This is the renamed repository of the original Specialist Publisher, the compositional (or 'hexagonal')
Rails app based heavily on dependency injection.


Specialist Publisher has been divided into two publishing applications to accommodate Specialist Documents and Manuals separately.
_Specialist Document_ or _Finders_ publishing now lives at https://github.com/alphagov/specialist-publisher

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

Then start the application:

```
$ ./startup.sh
```

If you are using the GDS development virtual machine then the application will be available on the host at http://manuals-publisher.dev.gov.uk/

## Running the test suite

```
$ bundle exec rake
```

Note: The `cucumber` rake task which is run as part of the `default` rake task does not work with `bundler` versions of 1.13.0 onwards. The following exception occurs: `cannot load such file -- active_model/translation (LoadError)`. The full stack trace is recorded [here](https://gist.github.com/floehopper/79341ba0205a7d95fe0cd8ca369f8551).

## Application directory structure

Non standard Rails directories and what they're used for:

* `app/exporters`
  These export information to various GOV.UK APIs
  * `app/exporters/formatters`
    These are used by exporters to format information for transferring as JSON
* `app/importers`
  Generic code used when writing importers for scraped content of new document formats
* `app/models`
  Combination of Mongoid documents and Ruby objects for handling Documents and various behaviours
  * `app/models/builders`
    Ruby objects for building a new document by setting ID and subclasses for setting the document type, if needed
  * `app/models/validators`
    Not validators. Decorators for providing validation logic.
* `app/observers`
  Define ordered lists of exporters, called at different stages of a document's life cycle, for example, publication
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
