# -*- coding: utf-8 -*-

class Admin::NewsItemsController < AdministrationController

  cache_sweeper :news_item_sweeper, :only => [ :create, :update, :destroy ]

  active_scaffold :news_item do |config|
    config.label = 'News Items'

    config.list.columns = [ :last_edit, :author, :title, :description_raw ]

    config.create.label = 'Create News Item'
    config.create.link.label = 'New News Item'
    config.create.columns = [ :title, :description_raw ]

    config.update.columns = [ :title, :description_raw ]

    config.show.label = 'Show News Item'
    config.show.columns = [ :title, :description_raw, :description_encoded, :author, :created_at, :updated_at ]

    # Disable sorting of the title and description columns
    config.columns[:title].sort = false
    config.columns[:description_raw].sort = false

    # Label overrides
    config.columns[:created_at].label = 'Creation Time'
    config.columns[:updated_at].label = 'Last Update Time'
    config.columns[:description_raw].label = 'Text'
    config.columns[:description_encoded].label = 'Formatted Text'

    # Virtual fields
    config.columns << :last_edit
    config.columns[:last_edit].label = 'Time'
    config.columns[:last_edit].sort = true
    config.columns[:last_edit].sort_by :sql => 'COALESCE(news_items.updated_at, news_items.created_at)'

    # Required fields
    config.columns[:title].required = true
    config.columns[:description_raw].required = true

    # List config
    config.list.sorting = { :last_edit => :desc }
    config.list.per_page = 20

    # UI overrides
    config.columns[:title].options = { :size => 64, :maxlength => 255 }
    config.columns[:description_raw].form_ui = :textarea
    config.columns[:description_raw].options = { :cols => 80, :rows => 12 }
  end

  protected

    def before_create_save(record)
      record.author_id = session[:user_id]
    end

    def before_update_save(record)
      record.author_id = session[:user_id]
    end

end
