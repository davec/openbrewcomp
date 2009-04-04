# -*- coding: utf-8 -*-

# This controller handles the login/logout function of the site.  

class SessionsController < ApplicationController

  # render new.rhtml
  def new
  end

  def create
    logout_keeping_session!
    anonymous_login = params[:anonymous] == '1'
    user = anonymous_login \
      ? User.anonymous_user \
      : User.authenticate(params[:user][:login], params[:user][:password])
    if user
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session

      new_cookie_flag = (params[:remember_me] == '1')
      handle_remember_cookie! new_cookie_flag
      setup_user_session(user)
    else
      note_failed_signin(anonymous_login)
      @remember_me = params[:remember_me]
      render :action => 'new'
    end
  end

  def destroy
    logout_killing_session!
    #flash[:notice] = 'You have been logged out.'
    redirect_back_or_default(login_path)
  end

  protected

    # Track failed login attempts
    def note_failed_signin(anonymous_login)
      #flash[:error] = "Could not log you in as '#{params[:user][:login]}'"
      flash[:login_error] = anonymous_login ? 'Anonymous login failed, please try again later' : 'Invalid login credentials'
      logger.warn "Failed login for '#{anonymous_login ? 'anonymous' : params[:user][:login]}' from #{request.remote_ip} at #{Time.now.utc}"
    end

end
