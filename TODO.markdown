This is a list of potential changes for OpenBrewComp, in no particular order.

* Migrate to Rails 2.3
* I18n/L10n work.
* Resolve CSS issues with the flight management pages in IE.
* Use role_requirement plugin instead of our hand-rolled roles+rights. (Not
  sure how this would work with the entrant, entry, and judge controllers.)
* Provide a way to handle duplicate records, specifically cases where an
  entrant registers under two similar, but slightly different, names.
* Add support for assigned scores, i.e, the combined score assigned by the
  judge panel, instead of automatically generated average scores (though judge
  panels seem to compute an average score for the assigned score anyway).
* Have the ability to generate a partial BOS pull sheet before the completion
  of all second round flights (to reduce the delay in sitting the BOS panel
  after the completion of second round).
* Include scores in the flight show panel.
* Improved handling of judge signup. As currently written, BJCP IDs must be
  unique, but if a judge attempts to sign up without using the registration
  key sent in the email invite, they're prevented from doing so because they're
  already listed in the judge table.
  on the page when fewer than 3 bottles are required.
* Also need to investigate the ramifications of requiring more than 3 bottles
  for a category, though such a requirement is unlikely which probably puts this
  item at a very low priority.
