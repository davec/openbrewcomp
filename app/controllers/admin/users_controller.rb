# -*- coding: utf-8 -*-

class Admin::UsersController < AdministrationController

  filter_parameter_logging :password

  active_scaffold :user do |config|
    config.label = 'Users'

    config.list.columns = [ :login, :name, :email, :enabled, :is_admin, :created_at, :last_logon_at ]

    config.create.label = 'Create User'
    config.create.link.label = 'New User'
    config.create.columns = [ :login, :name, :email, :password, :password_confirmation, :is_admin, :roles ]

    config.update.columns = [ :login, :name, :email, :password, :password_confirmation, :is_admin, :enabled, :roles ]

    config.show.label = 'Show User'
    config.show.columns = [ :login, :enabled, :is_admin, :name, :email, :created_at, :updated_at, :last_logon_at, :roles ]

    # Label overrides
    config.columns[:created_at].label = 'Creation Time'
    config.columns[:updated_at].label = 'Last Update Time'
    config.columns[:last_logon_at].label = 'Last Logon Time'

    # List config
    config.list.sorting = { :login => :asc }
    config.list.per_page = 100

    # UI overrides
    config.columns[:roles].form_ui = :select
  end

  # Some user accounts may be protected against deletion, or an error may
  # occur when deleting an account. Therefore, we must catch any exception
  # raised by the destroy processing so that a message can be displayed to
  # the user (otherwise the deletion just silently fails and the user is
  # left wondering why the account wasn't deleted).
  #
  # Even though the UI disables the 'Delete' link, we still need to protect
  # against a user accessing the URL directly.
  def destroy
    begin
      super
    rescue ActiveScaffold::RecordNotAllowed => e
      raise e
    rescue Exception => e
      send_flash(e.message)
    end
  end

  # Some user accounts may be protected against certain edit actions, or an
  # error may occur when editing an account. Therefore, we must catch any
  # exception raised by the edit processing so that a message can be displayed
  # to the user (otherwise the edit just silently fails and the user is left
  # wondering why the account wasn't modified).
  def update
    begin
      super
    rescue Exception => e
      send_flash(e.message)
    end
  end

  protected

    def conditions_for_collection
      # Disregard anonymous accounts
      [ 'is_anonymous = ?', false ]
    end

  private

    def send_flash(message)
      flash[:warning] = message
      render :update do |page|
        page.replace_html active_scaffold_messages_id, :partial => 'messages'
      end
    end

end
