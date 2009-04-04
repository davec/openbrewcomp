# -*- coding: utf-8 -*-

class Admin::MainController < AdministrationController

  def index
    @toc = [ TocChapter.new('Registration', [ 'entrants', 'entries', 'judge_invites', 'exports' ]),
             TocChapter.new('Reporting', [ 'reports', 'entries_with_styleinfo', 'box_check' ]),
             TocChapter.new('Competition', [ 'competition_data', 'judging_sessions', 'flights', 'judges', 'entry_scores', 'results' ]),
             TocChapter.new('Styles', [ 'categories', 'awards', 'styles', 'carbonation', 'strength', 'sweetness' ]),
             TocChapter.new('Users', [ 'users', 'roles', 'rights' ]),
             TocChapter.new('Site Maintainance', [ 'contacts', 'news_items', 'rounds', 'judge_ranks', 'point_allocations', 'countries', 'regions', 'clubs', 'imports', 'purge_old_data' ]) ]

    @allowed_controllers = current_user.roles.collect{|role| role.rights.collect(&:controller).uniq}.flatten
  end

end
