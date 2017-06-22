# Fully-migrated spike

In June 2017, we ([Go Free Range](http://gofreerange.com)) spiked on the idea of converting the app to use the Publishing API as its canonical/only persistence mechanism. This work was captured in the [`spike-fully-migrated-wrt-publishing-api` branch](https://github.com/alphagov/manuals-publisher/compare/spike-fully-migrated-wrt-publishing-api). The following notes record our discoveries and highlight potential problems.

## Reading list of manuals

- Working OK

## Reading single manual and its sections

- Working OK

## Reading single section and its attachments

- Working OK

## Saving of attachments

- This had to change a bit, because the attachments are embedded in sections in the local database. When we switch to using the Publishing API for persistence, we can no longer rely on the local database, and so we have to save the attachment's section to the Publishing API.

## Change notes

- Currently never **read** from the Publishing API so no changes needed.

- Currently uses custom attribute in details hash passing through Publishing API - does not use either of the official Publishing API mechanisms.

## Scoping based on user's role/organisation

- We've solved this in the spike when loading all manuals by using `get_content_items` in conjunction with the `link_organisations` option and when loading a single manual by using `get_content` and checking the manual's organisation matches that of the user.

- It's not completely obvious where this logic should live, but we're confident we can make it work.

## Publishing (asynchronous)

- It looks as if we can keep this as it is for now, although that will mean keeping the local database in order to persist the instances of `ManualPublishTask` which represent the publish jobs queued by `Manual::QueuePublishService` and processed by `PublishManualWorker`.

- We think this is currently done asynchronously because we need to call `patch_links`, `put_content` & `publish` for the manual *and each of its sections* which could easily be a lot of calls to the Publishing API.

- Once we're using the Publishing API for persistence, we suspect we may not need to call `patch_links` or `put_content`, only `publish`, and this may mean it's no longer so important to do this asynchronously. But it's probably simplest to keep it as it is, although see the issue about `VersionMismatchError` below.

## Version number / `VersionMismatchError`

- We think `Manual#version_number` is always set to 0 at the moment in the spike, i.e. we don't think it's being set from the Publishing API. This is incorrect and the only reason we don't see a `VersionMismatchError` is because `0 == 0!`

- It looks as if there is [a bug in `master`](https://github.com/alphagov/manuals-publisher/issues/1177) which means that this exception is never raised, so in a way we don't need to do anything in the spike to replicate this behaviour!

- If we need to, we can obtain the version number from the Publishing API via the `state_history` by finding the highest version number key in the Hash. However, it's worth noting that it looks as if the version number is not incremented if you keep saving a draft. We don't know whether it's a coincidence, but this behaviour actually matches what's happening in `master` with the version number stored in the local database.

- As we mentioned in the GitHub issue (see above), we think the best way to fix this is to prevent edits to a draft which is queued for publication.

## Edit first publication date for manual

- Are we loading these timestamps correctly and/or do we need to load them correctly?

- Publishing API: `first_published_at`, `public_updated_at`

- Manual: `originally_published_at`,
  `use_originally_published_at_for_public_timestamp?`

## Pagination of manuals and sections

- As far as we can see, although at one point the app used Kaminari to do pagination, it doesn't currently.

- The `get_content_items` method we plan to use for the manuals index page paginates results by default (50 per page).

- At a minimum, we will need to ensure that all manuals are listed, even if it is more than 50, because that is the current behaviour.

- The simplest way to do this may be to set the `per_page` option `get_content_items` on to a very large number; much bigger than the number of manuals in production. we have verified that this works and there doesn't appear to be any maximum value as far as the Publishing API is concerned.

- We've tried to load the manuals index page with recent production data and it times out because the SQL query in Publishing API takes ~9 seconds. So we think we're going to need to re-think this and probably introduce pagination of some sort.

- It looks as if Specialist Publisher does pagination using Kaminari and passes the various pagination options on to the Publishing API
  - [Kaminari paginate helper method](https://github.com/alphagov/specialist-publisher/blob/6182aa430313c72683c033047081e1d7daef030f/app/views/documents/index.html.erb#L22)
  - [PaginationPresenter](https://github.com/alphagov/specialist-publisher/blob/6182aa430313c72683c033047081e1d7daef030f/app/presenters/pagination_presenter.rb)

## Performance

- As mentioned above, when we run the whole system with production-like data, we start running into timeouts with calls to the Publishing API. We've seen this when trying to load a lot of manuals on the index page (see above), but also when trying to create a new section on a draft manual. In this case, at first glance, the slowest queries we could see were ones to do with loading or updating links.

- One optimisation we can imagine is if we stop putting the association between manuals & sections and vice versa in the details hash, and instead rely entirely on the links in the Publishing API, we could avoid some operations, e.g. no need to save manual content when adding or removing a section; we could just update the links.

- However, this could all be a bit of a blocker. We can imagine we might need to tune the queries in the Publishing API which we can imagine taking a lot of time.
  - An alternative solution might be to add more attributes to the details hash so we can avoid/reduce calls to get links.
  - Also we might be able to avoid reloading a bunch of data when processing a form submission if we store extra data as hidden fields in the form.

## Validation errors

- Given that we'll be building the same domain model objects in memory even though we'll have read the data from the Publishing API, we think the existing validation will continue to work.

- However, we suspect it could probably be improved in order to ensure we avoid as many Publisher API exceptions as possible.

- Alternatively we might want to remove all validation from Manuals Publisher and instead rely on exceptions from the Publishing API.

- We'd prefer keeping the duplication of having the validation in the Manuals Publisher app because we think it will give a better user experience.

## Other API errors

- Since we should only be adding methods which **read** the Publishing API, we think it's safe to assume that we won't encounter any API errors unless something very out of the ordinary has occurred, in which case an un-handled exception is probably OK and will be seen in Errbit.

- The only possible exception to this is when content items are not found.

## Display full state information in manuals index page

- Including "published with new draft" & "withdrawn with new draft".

- We've implemented this in the spike based on [this document in the Specialist Publisher repo](https://github.com/alphagov/specialist-publisher/blob/master/docs/phase-2-migration/composed-states.md). In particular we've copied the [`StateHelper`](https://github.com/alphagov/specialist-publisher/blob/ac002d8ffd7bb900142220012a2f700c6d2cc2f2/app/helpers/state_helper.rb) class over in its entirety, because we're using almost all of its methods. The `StateHelper#state_for_frontend` method does what we need as long as we supply it with a document with a `state_history` which is available from calls to `get_content_items` and `get_content`.

## Slug uniqueness check

- For now we've implemented this using the existing `PublishingAdapter#all` method and then checking all the slugs in memory.

- It would probably be more efficient to do the query as part of a custom call to `get_content_items`, i.e. using the `search_in` and `q` options for the `base_path` attribute.

## Avoid N+1 calls to Publishing API in `PublishingAdapter#find`

- We've successfully updated the implementation of `PublishingAdapter#find` to load data for all the sections in a single call to `get_content_items` and then use the `section_uuids` obtained from `get_links` to order them appropriately

## Withdrawing

- Via the current user interface, this is only allowed for a section, not a manual. The way it currently seems to work is that `discard_draft` is called for the section on the Publishing API. Our understanding is that this will only have an effect if there a draft of the section exists and it will replace the draft section with the latest published section in the Draft Content Store. When the manual is next published, the `unpublish` method is called on the Publishing API for sections which have been withdrawn (`Manual#removed_sections`).

- It's not going to be straightforward to replicate this behaviour when using the Publishing API for persistence. In order to do so, we think we'd need to somehow mark the sections as "removed" in the Publishing API, perhaps using the details hash and then only actually unpublish them when publishing their manual. It might make sense for this behaviour to live within the Publishing API but then that's going to be even more work.

- An alternative is to un-publish sections immediately on withdrawal, i.e. don't wait until we next publish the manual.  However, we suspect this might not be acceptable to users, because a manual might be in an inconsistent state over an extended period.

## Consistency

- Before switching over to using the Publishing API as the canonical persistence mechanism it would be advisable to check that all the data in the local database for existing content is already in the Publishing API.

- We don't think it's safe to assume that older content has been saved to the Publishing API using the same attribute hash and it's possible some content items pre-date the Publishing API and were never added. Thus it would probably be sensible to re-publish all documents before switching over.

## Re-publishing

- This is not currently possible via the user interface, although it is probably one of the Rake tasks which we will need to keep in case e.g. the content schema changes.

- At first glance, the only complication we can see is how to implement `Manual#current_versions` which finds the latest published and latest draft versions if either exists, but we're fairly confident that should be possible.

- We can't find any documentation for the `update_type` supplied to `put_content` or `publish`, especially what it means to set it to "republish". Our best guess is that it just means used the timestamps from the previous edition so that it looks as if it was saved/published at the time it was originally saved/published, but we're not sure about that.

## Rake tasks / scripts

- We would suggest removing the code from these and simply displaying a message suggesting the user contact whoever is switching the app over to use the Publishing API as the canonical/only persistence mechanism.

- As mentioned above, we probably need to retain some kind of republishing capability. We believe Specialist Publisher has a Rake task for republishing everything.

## Fixing / re-writing specs & features

- This could involve quite a bit of work, although it should mostly be a matter of removing database setup and replacing it with stubs on the `PublishingAdapter`.

- No attempt was made to do this in the spike branch.

- In parallel with the spike we made a start on actually implementing the switchover for attachments. We tried to do this in incrementally by firstly changing the app to read from the Publishing API instead of the database, but still saving the attachments to the database; and secondly removing the code which saves the attachments to the database. The idea was that this would reduce the size of the commits, particularly the changes needed in the specs/features. However, it turned out that this introduced complications and we came to the conclusion it would probably be better to make the change in a single step.

## Removing persistence-related code & database

- Although it should be relatively straightforward, there would be quite a bit of persistence-related code to remove. Essentially the domain models should end up as `ActiveModel` classes with little, if any, behaviour i.e. mainly just attributes & validation. Also there will probably be no need to model manual/section editions separately.

- Once the switchover has happened, it would be good to remove the relevant tables from the database.
