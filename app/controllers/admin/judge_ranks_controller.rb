# -*- coding: utf-8 -*-

class Admin::JudgeRanksController < AdministrationController

  active_scaffold :judge_rank do |config|
    config.actions << :sortable
    config.columns = [ :description ]
    config.label = 'Judge Ranks'

    config.create.label = 'Create Judge Rank'
    config.create.link.label = 'New Judge Rank'

    config.show.label = 'Show Judge Rank'

    # Required fields
    config.columns[:description].required = true

    # UI overrides
    config.columns[:description].options = { :size => 40, :maxlength => 40 }
  end

end
