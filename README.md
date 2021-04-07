# Manuals publisher

Publishing app for manuals. E.g. [The Highway Code].

## Nomenclature

* Manual: Parent document which is made up of a number of sections
* Section: Individual segment / page of a Manual
* Attachment: File attachment which can be added to a section

## Technical documentation

This is a Ruby on Rails app, and should follow [our Rails app
conventions][conventions].

You can use the [GOV.UK Docker environment][govuk-docker] to run the
application and its tests with all the necessary dependencies. Follow the
[usage instructions][docker-usage] to get started.

### Running the test suite

```
$ bundle exec rake
```

## Documentation

* [History of the development of the application](docs/history.md)
* [Current state of the application](docs/current-state.md)
* [Information about Rake tasks](docs/rake-tasks.md)
* [Possible next steps for development](docs/next-steps.md)
* [Notes on investigation into fully migrating app with respect to Publishing API](docs/fully-migrated-spike.md)

[The Highway Code]: https://www.gov.uk/guidance/the-highway-code
[conventions]: https://docs.publishing.service.gov.uk/manual/conventions-for-rails-applications.html
[govuk-docker]: https://github.com/alphagov/govuk-docker
[docker-usage]: https://github.com/alphagov/govuk-docker#usage
