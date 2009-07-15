# -*- coding: utf-8 -*-

# This controller handles the login/logout function of the site.  

class SessionsController < ApplicationController

  # render new.rhtml
  def new
  end

  def create
    logout_keeping_session!
    if using_open_id?
      open_id_authentication
    else
      password_authentication
    end
  end

  def destroy
    logout_killing_session!
    #flash[:notice] = 'You have been logged out.'
    redirect_back_or_default(login_path)
  end

  protected

    def anonymous_login?
      params[:anonymous] == '1'
    end

    def open_id_authentication
      begin
        authenticate_with_open_id(params[:openid_url],
                                  :return_to => open_id_complete_url) do |result, identity_url|
          if result.successful? && user = User.find_by_identity_url(identity_url)
            successful_login(user)
          else
            failed_login(result.message || 'Sorry, no user with that identity URL exists')
          end
        end
      rescue Exception => e
        failed_login(e.to_s || 'Invalid identity URL')
      end
    end

    def password_authentication
      user = if anonymous_login?
               User.anonymous_user
             else
               User.authenticate(params[:user][:login], params[:user][:password])
             end
      if user
        self.current_user = user
        successful_login(user)
      else
        failed_login(anonymous_login? ?
                     'Anonymous login failed, please try again later' :
                     'Invalid login credentials')
      end
    end

    def successful_login(user)
      new_cookie_flag = (params[:remember_me] == '1')
      handle_remember_cookie! new_cookie_flag
      setup_user_session(user)
    end

    def failed_login(message = 'Login failed')
      account = if using_open_id?
                  params[:openid_url]
                elsif anonymous_login?
                  'anonymous'
                else
                  params[:user][:login]
                end
      logger.warn "Failed login for '#{account}' from #{request.remote_ip} at #{Time.now.utc}"

      error_target = using_open_id? ? :openid_error : :login_error
      flash[error_target] = message
      @remember_me = params[:remember_me]
      render :action => :new
    end

end
