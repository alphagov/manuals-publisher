# History

This repository was forked from the [specialist-publisher repository][] in November 2015, thus the two repositories have the first ~1800 commits in common. The last commit which the two repositories have in common is [this one][last-common-commit].

Immediately after the fork the code in specialist-publisher was [all removed][delete-everything-commit] and the application re-written from scratch to support publishing of specialist documents using the Publishing API as the canonical/only persistence mechanism.

At the point when the fork happened the application in *this* repository (now called `manuals-publisher`) was responsible for publishing both manuals (and their sections) *and* specialist documents. The application was originally written in Feb 2014 and started life only being able to [publish specialist documents][specialist-documents-commit]. Publishing of manuals and their sections was added in Apr/May 2014 in [PR #76][] & [PR #78][].

The application had been developed in a rather unconventional fashion - using a [custom dependency-injection container][dip-container] and the [Domain-Driven Design][] / [Hexagonal Architecture][] idea of decoupling the persistence mechanism from the domain model using repository classes. The app also contained extensive use of anonymous procs and classes with a single `#call` method.

In September 2016 the Rails app in this repository was [renamed from `SpecialistPublisher` to `ManualsPublisher`][app-rename-commit]. In October 2016, the UI for publishing specialist documents was [removed][specialist-document-ui-removed]. Presumably before this point the re-written specialist-publisher app had taken over responsibility for publishing specialist documents.

By early 2017 this application had become extremely difficult to maintain. The unconventional architecture had led to so many levels of indirection that it was extremely difficult to understand what effect executing a single controller action would have. It looks as if one consequence of this was that bug fixes and enhancements sometimes worked *around* the architectural patterns rather than with them, making the codebase even more confusing.

From March 2017, developers from [Go Free Range][] spent a couple of months refactoring the codebase towards a simpler and more conventional Rails app. The dependency injection container was removed, many levels of indirection were collapsed, and anonymous procs were converted into named classes. The remaining code and data associated with specialist documents was removed and the main gems used by the application (Rails, Mongoid, etc) were upgraded to much more recent versions. The current state of the codebase is described in more detail [here](current-state.md).

While investigating converting the domain model to be a more standard set of `Mongoid::Document` classes with all relationships defined as Mongoid associations, they decided that it might be simpler to convert the app to "fully-migrated" status with regard to the Publishing API, i.e. to use the Publishing API as the canonical/only persistence mechanism in the app. Their exploration of this idea is captured [here](fully-migrated-spike.md) and their ideas for possible next steps are recorded [here](next-steps.md).

[specialist-publisher repository]: https://github.com/alphagov/specialist-publisher
[last-common-commit]: https://github.com/alphagov/manuals-publisher/commit/fd3ac12a2a5e4b4e48b79bb5dce0d211add53848
[delete-everything-commit]: https://github.com/alphagov/specialist-publisher/commit/e7dc17bf8dc57bfbc807f12d2373b27042bb296a
[app-rename-commit]: https://github.com/alphagov/manuals-publisher/commit/3120a8755d6774ba2a0db0589016f6eacd043e01
[specialist-documents-commit]: https://github.com/alphagov/manuals-publisher/commit/ce78da77a0e8bb30fd253633da2b7640eebbf66e
[Domain-Driven Design]: https://en.wikipedia.org/wiki/Domain-driven_design
[Hexagonal Architecture]: http://alistair.cockburn.us/Hexagonal+architecture
[dip-container]: https://github.com/alphagov/manuals-publisher/blob/de505410d77af97f39b3531c2c3709ebea17fcef/lib/dependency_container.rb
[specialist-document-ui-removed]: https://github.com/alphagov/manuals-publisher/commit/3162f0e72fd53bfd1cf87f5661bb198ff785940e
[Go Free Range]: http://gofreerange.com
[PR #76]: https://github.com/alphagov/manuals-publisher/pull/76
[PR #78]: https://github.com/alphagov/manuals-publisher/pull/78
