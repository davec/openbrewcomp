# OpenBrewComp

OpenBrewComp is a web application that provides a basis for running a homebrew
(beer/mead/cider) competition. The code was originally written to provide an online
registration system for the 2007 Dixie Cup competition and was expanded in 2008 to
include additional features necessary to run the entire competition, including
flight management and tabulation of results. Additional features, not required by
the Dixie Cup, were added for the 2008 Fall Classic competition. The two code
bases have been distilled into a single code base that will allow other homebrew
clubs to build their own competition management systems using a battle-tested open
source code base.

## Features

For the brewer entering a competition, the OpenBrewComp system offers

+ The ability to register entries and sign up for judging at any time during
  the registration period
  - by creating an account that can be used for subsequent sessions to add,
    modify, and delete entries, thus eliminating the necessity of having to
    enter all entries at once. Entry modifications are not permitted once an
    entry has been processed (by being assigned a bottle code) so the entrant
    cannot, for example, reassign an entry to a different category after it has
    been accepted into the competition); or
  - by creating a temporary (anonymous) account and entering all entries at once.
+ A single brewer may create multiple entrant records under their account so,
  for example, a brewer who is entering one set of entries as a solo brewer and
  another set of entries as part of a team can create separate entrant records
  and register the corresponding entries under the appropriate entrant record.
+ Automatically generated bottle labels, either individually or combined into
  a single PDF file, that includes the brewer&rsquo;s information and the assigned
  registration code for each entry.

For the competition organizer, the OpenBrewComp system offers

+ Configurable competition parameters such as
  - the dates during which online registration is available for both entries and
    judges (since the two periods are often not the same);
  - the styles to be judged, either with special styles that are in addition to
    the standard BJCP styles or the elimination of styles that are not being
    judged in the competition;
  - managing the grouping of styles into award categories if the award categories
    do not line up with the standard 28 BJCP categories.
+ Registration of entries that were not entered online.
+ Easy assignment of bottle codes to registered entries.
+ The ability to quickly identify all entries that have supplemental information
  provided. If any of the information is inappropriate, the organizer can edit
  it as necessary. This information is printed on the flight sheets for the
  judges, so no personally identifiable information should be included.
+ Generation of a &ldquo;box check report&rdquo; that allows you to verify that
  all registered entries are accounted for and placed in the appropriate boxes.
+ The ability to import the BJCP judge list provided in your competition
  registration packet as well as the ability to send email invites to those
  judges.
+ Automatic generation of an initial set of first round flights that can be
  fine-tuned with a drag-and-drop interface.
+ Management and tracking of flights, including judge/steward assignments and
  the recording of scores, which entries get advanced to the next round (in
  multi-round flights), and the ranking (first, second, third, and honorable
  mention) of entries in the medal round.
+ Automatic generation of flight pull and judge sheets. The judge sheets include
  any supplemental information for each entry in the flight.
+ Automatic generation of the list of winners.
+ Automatic generation of the BJCP competition report in the format required
  by the BJCP for electronic submission.
+ Automatic generation of the MCAB competition report, if the competition is
  a MCAB QE.
+ Automatic generation of cover sheets for each entrant, listing all of their
  entries, to group their score sheets.
+ If Internet access is not available at the competition site, the database can
  be downloaded from the main server and loaded onto a laptop that is running a
  copy of the OpenBrewComp software.
+ Various reports breaking down the entry counts by individual, club, style,
  and state/province.
+ Customization of the entire system since you have the source code. If there
  are any elements that are not necessary for your competition, for example you
  don&rsquo;t bother with having judges pre-register, those elements can be
  easily removed.

OpenBrewComp does not currently have the ability for users to pay their entry fees
online via PayPal or another credit card processor. Such functionality was not
a requirement of the original competitions, but there are no known technical reasons
it could not be added. If you add such capability, please consider contributing
your changes back for the benefit of other clubs.

## Requirements and Caveats

OpenBrewComp requires familiarity with Ruby on Rails and UNIX system administration.
The application has, so far, only been run on UNIX-based systems. No attempt has yet
been made to run the application on a MS Windows system.

The user interface, being web-based, will work in any modern JavaScript-enabled
graphical browser. Some parts of the system are known to not work with JavaScript
disabled, or when using a text-based browser. The original requirements of the
system did not require it to work under such conditions so minimal effort was
spent addressing such environments.

## Dependencies

+ [Ruby](http://www.ruby-lang.org/) 1.8.6 (not tested with 1.8.7 or 1.9)
+ [Ruby on Rails](http://rubyonrails.org/) 2.2.x
+ A supported database (tested with [PostgreSQL](http://www.postgresql.org/) 8.3.7,
  [MySQL](http://www.mysql.com/) 5.0.77, and [SQLite}(http://www.sqlite.org/) 3.6.11)
+ A working [LaTeX](http://www.latex-project.org/) installation such as the one
  provided by [TeXLive](http://www.tug.org/texlive/) (tested with TeXLive 2007
  and 2008), though any modern TeX system should work. The following packages
  are used: `array`, `booktabs`, `colortbl`, `epic`, `geometry`, `graphicx`,
  `inputenc`, `longtable`, `multicol`, `pifont`, and `textpos`.

OpenBrewComp makes use of several gems and plugins. The required plugins are
included in the distribution and the gems can be easily installed. Run `rake gems`
to see the list of gems. You must include http://gems.github.com in your gems
sources before installing the gems.

## Setup

Once you have a supported database server installed and a working installation
of Ruby on Rails,

1. Download the source, either `git clone git://github.com/davec/openbrewcomp`
   or download a zip or tar archive by clicking the _download_ button at the
   top of the project&rsquo;s github page and unzip/untar it to a local directory.
2. Copy `config/database.yml.example` to `config/database.yml` and edit it for
   your environment.
3. Run `rake setup` to generate the required configuration files.
4. Run `rake gems:install` to install the required gems.
5. Edit `db/fixtures/contacts.yml` and set the contact information for your
   competition coordinator and webmaster.
6. (optional) Edit `db/fixtures/clubs.yml` to set an initial list of clubs
   that will be shown in a selection box for an entrant. This is not strictly
   necessary since entrants will be able to add their club&rsquo;s name to the
   list if it does not already exist in the database but an initial list of clubs
   that only has your own club name doesn&rsquo;t look so good.
7. Create your development, test, and production databases: `rake db:create:all`
8. Initialize your development database: `rake db:bootstrap`

## Testing

Run the tests with `rake test` which will perform some basic functionality tests.
If anything fails, you need to investigate the failure(s) before proceeding.

Note that the functional tests generate a large number of deprecation warnings.
These warnings are expected and are not a problem.

## Customizing

Several files need to be customized for your site before turning it loose on
the world.

<dl>
  <dt><code>app/models/style.rb</code></dt>
  <dd>
    <p>
      Modify the <code>number_of_bottles_required</code> method as appropriate
      for your competition. The default is 3 bottles for &ldquo;point
      qualifying&rdquo; styles, i.e., those that are judged in a best-of-show
      flight, and 2 bottles for all other styles.
    </p>
  </dd>

  <dt><code>app/models/award.rb</code></dt>
  <dd>
    <p>
      The <code>MAX_ENTRIES</code> variable defines the maximum number of
      entries <b>per award category</b>, and defaults to 2. Set this value as
      appropriate for your competition. If you do not impose a limit, set it
      to <code>nil</code>.
    </p>
    <p>
      Note, however, that this is not a hard limit and does not prevent someone
      from actually entering more than the allowed number of entries &mdash; an
      annoying warning message will be displayed with each entry that is
      registered in excess of the maximum value &mdash; but it is the responsibility
      of the competition organizer to enforce the limit, and an administrative
      report is available to identify such entries.
    </p>
    <p>
      If your competition imposes some other type of entry limits, for example,
      on a per-style basis, other code modifications will be required.
    </p>
  </dd>

  <dt><code>config/initializers/action_mailer.rb</code></dt>
  <dd>
    <p>
      Configure your email server settings. Failure to set these correctly will
      prevent any email from being sent.
    </p>
  </dd>

  <dt><code>config/initializers/exception_notifier.rb</code></dt>
  <dd>
    <p>
      Configure the recipients for email notification of any exceptions that
      are encountered in the production environment.
    </p>
  </dd>

  <dt><code>config/initializers/session_cleanup.rb</code></dt>
  <dd>
    <p>
      Configure database-stored session expiry time. The default is 2 hours.
      You will need to create a cron job to periodically perform the cleanup.
    </p>
    <p>
      The following shell script, called periodically from a cron job will
      purge the expired sessions:
    </p>
    <pre>#!/bin/sh
# Usage: expire-rails-sessions application environment
if [ $# -eq 2 ] ; then
  cd /var/www/rails/$2/$1/current
  script/runner -e $2 SessionCleanup.purge_expired_sessions
else
  echo "Usage: $0 application environment"
fi</pre>
    <p>
      As an alternative to the database-stored sessions, you may prefer to
      use the default cookie-based session storage instead. If so, modify
      <code>config/environment.rb</code> and comment out the setting for
      <code>config.action_controller.session_store</code>.
    </p>
  </dd>

  <dt><code>app/models/judge_invite.rb</code></dt>
  <dd>
    <p>
      The judge invite template can be modified to suit your taste. This is
      the message template that is shown on the Judge Invites page, and
      unless you want to permanently change the default message, you do not
      need to make any changes here and can make one-time modifications when
      you send the invites.
    </p>
  </dd>
</dl>

### International Issues

By default, the system will accept entries from brewers in the United States
and Canada. Settings in the administrative interface control the display of
countries and testing has shown no problems with including other countries
that generally follow similar postal addressing formats, e.g., Australia,
Brazil, and Mexico.

Inclusion of other countries in the registration form is a simple matter of
setting an option in the countries table. However, support for countries
that do not generally follow US/Canada addressing formats, e.g., most of
Europe, will require some modifications to the registration form.

Since this application was originally built for competitions in the US, the
addresses printed on the entrant cover sheets assume that they will be mailed
from within the US and only append a country name for non-US recipients. If
you are located outside the US, a simple change can be made to change the
addressing behavior; edit the `include_country_in_address?` method in
`app/models/country.rb`.

### Customizing the Presentation

Adjust the page layouts (in the `app/views/layouts` directory) and tweak the
CSS (in the `public/stylesheets` directory) to customize the look for your
competition.

Several pages are provided as stubs in the various `app/views/*` directories.
You should modify these files as appropriate for your site.

### Customizing the Results

The layouts for reporting the results of the competition are located in the
`app/views/admin/results` directory. `bjcp.html.erb`, `bjcp.xml.builder`,
`mcab.html.erb`, and `_mcab.html.erb` should not require any modification.

The cover sheets for returned score sheets are specified in `entrant_covers.rtex`
which needs to be edited to specify the proper return address for your
competition. Search for `ReturnAddr` and make the appropriate modifications to
the address elements. You are, of course, free to modify the return address
section in any way you want, as long as it is valid LaTeX code.

## Running the Application

Initial testing should be performed in a development/test environment on your
local system. A development environment is typically started by running
`script/server`, but if you have another development environment set up, e.g.,
you are using Phusion Passenger for your development work, then use whatever
you are accustomed to using for developing a Rails application.

## Deployment

A sample `config/deploy.rb` file for use with [Capistrano](http://www.capify.org/)
is provided. Read the comments in the file and make the appropriate changes as
required for __your__ environment before attempting a deployment. After making
the appropriate changes to `deploy.rb` and creating the production database,
the initial deployment can be performed with the following steps:

    cap deploy:setup
    cap deploy:bootstrap

Past versions of the software have been deployed to groups of
[mongrel](http://mongrel.rubyforge.org/) servers, but more recently
[Phusion Passenger](http://www.modrails.com/) has been used.

## Contributing

Fork the source, hack away, push it up, and send a pull request.

## Copyright

Copyright © 2007-2009 David Cato
