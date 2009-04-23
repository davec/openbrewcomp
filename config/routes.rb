ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "main"

  # See how all your routes lay out with "rake routes"

  # Restful Authentication Routes
  map.login            '/login',           :controller => 'sessions',  :action => 'new'
  map.logout           '/logout',          :controller => 'sessions',  :action => 'destroy'
  map.signup           '/signup',          :controller => 'users',     :action => 'new'
  map.forgot_password  '/forgot_password', :controller => 'passwords', :action => 'new'
  map.change_password  '/change_password/:reset_code', :controller => 'passwords', :action => 'reset'
  map.open_id_complete '/opensession',     :controller => 'sessions',  :action => 'create', :requirements => { :method => :get }
  map.open_id_create   '/opencreate',      :controller => 'users',     :action => 'create', :requirements => { :method => :get }
  map.open_id_update   '/openupdate',      :controller => 'users',     :action => 'update', :requirements => { :method => :get }

  map.resources :users, :member => { :change_password => :get,
                                     :update_password => :put }
  map.resources :passwords, :only => [ :new, :create, :destroy ],
                            :collection => { :update_after_forgetting => :post }
  map.resource :session, :only => [ :new, :create, :destroy ]

  # About
  map.about    '/about',       :controller => 'about',                        :conditions => { :method => :get }
  map.article  '/article/:id', :controller => 'about', :action => 'article',  :conditions => { :method => :get }
  map.contacts '/contacts',    :controller => 'about', :action => 'contacts', :conditions => { :method => :get }
  map.faq      '/faq',         :controller => 'about', :action => 'faq',      :conditions => { :method => :get }
  map.news     '/news',        :controller => 'about', :action => 'news',     :conditions => { :method => :get }
  map.privacy  '/privacy',     :controller => 'about', :action => 'privacy',  :conditions => { :method => :get }

  # Entries
  map.entries  '/entries',  :controller => 'entries',                        :conditions => { :method => :get }
  map.awards   '/awards',   :controller => 'entries', :action => 'awards',   :conditions => { :method => :get }
  map.rules    '/rules',    :controller => 'entries', :action => 'rules',    :conditions => { :method => :get }
  map.shipping '/shipping', :controller => 'entries', :action => 'shipping', :conditions => { :method => :get }

  # Styles
  map.styles         '/styles',          :controller => 'styles',                       :conditions => { :method => :get }
  map.all_styles     '/styles/complete', :controller => 'styles', :action => 'all',     :conditions => { :method => :get }
  map.special_styles '/styles/special',  :controller => 'styles', :action => 'special', :conditions => { :method => :get }
  map.connect        '/styles/:action',  :controller => 'styles'

  # Registration
  map.registration        '/register',        :controller => 'register',                      :conditions => { :method => :get }
  map.online_registration '/register/online', :controller => 'register', :action => 'online', :conditions => { :method => :get }
  map.registration_forms  '/register/forms',  :controller => 'register', :action => 'forms',  :conditions => { :method => :get }

  # Judge confirmation
  map.judge_confirmation '/judge_confirmation/:key', :controller => 'register',
                                                     :action => 'judge_confirmation',
                                                     :key => /[[:xdigit:]]{32}/,
                                                     :conditions => { :method => :get }

  # RSS
  map.rss_feed '/rss', :controller => 'feed', :action => 'news', :conditions => { :method => :get }

  # Admin routes
  map.admin '/admin', :controller => 'admin/main', :conditions => { :method => :get }
  map.namespace(:admin) do |admin|
    admin.resources :clubs, :competition_data, :contacts, :entry_scores, :news_items,
                    :point_allocations, :rights, :roles, :users,
                    :active_scaffold => true
    admin.resources :carbonation, :strength, :sweetness,
                    :judge_ranks, :judging_sessions, :rounds,
                    :active_scaffold => true, :active_scaffold_sortable => true

    admin.resources :categories, :active_scaffold => true,
                    :has_many => { :awards => :styles }
    admin.resources :awards, :active_scaffold => true,
                    :has_many => :styles
    admin.resources :styles, :active_scaffold => true

    admin.resources :countries, :active_scaffold => true,
                    :has_many => :regions
    admin.resources :regions, :active_scaffold => true

    admin.resources :entrants, :active_scaffold => true,
                    :has_many => :entries,
                    :collection => { :help => :get }
    admin.resources :entries, :active_scaffold => true,
                    :member => { :entrant => :get },
                    :collection => {
                      :print => :get,
                      :help => :get,
                      :bottle_labels => :get
                    }
    admin.resources :entries_with_styleinfo, :active_scaffold => true,
                    :member => { :entrant => :get }

    admin.resources :flights, :active_scaffold => true,
                              :active_scaffold_sortable => true,
                    :member => {
                      :add_flight => :post,
                      :assign_entry => :put,
                      :delete_flight => :delete,
                      :delete_flights => :delete,
                      :push => :post,
                    },
                    :collection => {
                      :assign => [ :get, :post ],
                      :manage => :get,
                      :round_1 => :get,
                      :round_2 => :get,
                      :round_3 => :get,
                      :all_flights => :get,
                      :print => :get,
                      :list_ineligible_judges => :get,
                      :ineligible_judges => :get,
                      :track => :get
                    }

    admin.resources :judges, :active_scaffold => true,
                    :collection => { :help => :get }

    # Box Check
    admin.box_check '/box_check', :controller => 'box_check'

    # Exports
    admin.export '/export', :controller => 'exports'

    # Imports
    admin.import        '/import',        :controller => 'imports'
    admin.import_db     '/import_db',     :controller => 'imports', :action => 'db',            :conditions => { :method => :get }
    admin.import_judges '/import_judges', :controller => 'imports', :action => 'judges',        :conditions => { :method => :get }
    admin.db_import     '/import_db',     :controller => 'imports', :action => 'import_db',     :conditions => { :method => :post }
    admin.judges_import '/import_judges', :controller => 'imports', :action => 'import_judges', :conditions => { :method => :post }

    # Judge Invites (index, send_email)
    admin.judge_invitations      '/judge_invitations',      :controller => 'judge_invites'
    admin.send_judge_invitations '/send_judge_invitations', :controller => 'judge_invites', :action => 'send_email', :conditions => { :method => :post }

    # Purge Old Data
    admin.purge      '/purge',      :controller => 'purge_old_data'
    admin.purge_data '/purge_data', :controller => 'purge_old_data', :action => 'purge', :conditions => { :method => :post }

    # Reports ()
    admin.reports                      '/reports',                  :controller => 'reports'
    admin.report_confirmed_judges      '/reports/confirmed_judges', :controller => 'reports', :action => 'report_confirmed_judges'
    admin.report_entries_by_club       '/reports/by_club',          :controller => 'reports', :action => 'report_entries_by_club'
    admin.report_entries_by_individual '/reports/by_individual',    :controller => 'reports', :action => 'report_entries_by_individual'
    admin.report_entries_by_region     '/reports/by_region',        :controller => 'reports', :action => 'report_entries_by_region'
    admin.report_entries_by_style      '/reports/by_style',         :controller => 'reports', :action => 'report_entries_by_style'
    admin.report_entries_by_team       '/reports/by_team',          :controller => 'reports', :action => 'report_entries_by_team'
    admin.report_excess_entries        '/reports/excess_entries',   :controller => 'reports', :action => 'report_excess_entries'

    # Results
    admin.results        '/results',                :controller => 'results'
    admin.bjcp_report    '/results/bjcp',           :controller => 'results', :action => 'bjcp'
    admin.entrant_covers '/results/entrant_covers', :controller => 'results', :action => 'entrant_covers'
    admin.entry_covers   '/results/entry_covers',   :controller => 'results', :action => 'entry_covers'
    admin.live_results   '/results/live',           :controller => 'results', :action => 'live'
    admin.mcab_report    '/results/mcab',           :controller => 'results', :action => 'mcab'
    admin.send_award     '/results/send_award',     :controller => 'results', :action => 'send_award',     :conditions => { :method => :post }
    admin.send_bos_award '/results/send_bos_award', :controller => 'results', :action => 'send_bos_award', :conditions => { :method => :post }
    admin.score_summary  '/results/scores',         :controller => 'results', :action => 'scores'
    admin.web_results    '/results/web',            :controller => 'results', :action => 'web'
  end

  # Error pages
  map.authorization_error '/denied', :controller => 'main', :action => 'error403'
  
  # Handle everything else as a customized 404 error
  map.error '*path', :controller => 'main', :action => 'error404'
end
