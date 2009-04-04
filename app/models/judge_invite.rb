# -*- coding: utf-8 -*-

class JudgeInvite < ActiveRecord::Base

  @@tokens = {
    :url        => [ '@@URL@@', "the confirmation URL" ],
    :first_name => [ '@@FIRST_NAME@@', "the judge’s first name" ],
    :last_name  => [ '@@LAST_NAME@@', "the judge’s last name" ],
    :full_name  => [ '@@FULL_NAME@@', "the judge’s full name" ],
  }.freeze
  cattr_reader :tokens

  def self.message_template
    contacts = Contact.to_hash
    coordinator_name = contacts['coordinator']['name']
    coordinator_email = contacts['coordinator']['email']
    competition_name = CompetitionData.instance.name
    competition_date = CompetitionData.instance.competition_date
    template = <<EOF
Dear #{@@tokens[:first_name].first},

You are invited to judge at the #{competition_name} on #{competition_date.strftime('%A, %B %e, %Y')}.

Please go to #{@@tokens[:url].first} to register.

If you have any questions, please contact the #{competition_name} organizer,
#{coordinator_name}, at #{coordinator_email} for assistance.
EOF
    template
  end

  def self.default_subject
    "You are invited to judge at #{CompetitionData.instance.name}"
  end

end
