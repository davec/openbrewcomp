# -*- coding: utf-8 -*-

class UsersController < ApplicationController
  before_filter :login_required, :except => [ :new, :create ]
  before_filter :login_prohibited, :only => [ :new, :create ]
  skip_before_filter :verify_authenticity_token, :only => :create
  
  def new
    flash.clear
    @user = User.new
  end
 
  def create
    redirect_to login_path and return if params[:cancel]
    flash.clear
    logout_keeping_session!
    if using_open_id?
      begin
        authenticate_with_open_id(params[:openid_url],
                                  :return_to => open_id_create_url,
                                  :optional => [:fullname],
                                  :required => [:nickname, :email]) do |result, identity_url, registration|
          if result.successful?
            create_new_user(:identity_url => identity_url,
                            :login => registration['nickname'],
                            :email => registration['email'],
                            :name => (registration['fullname'] || ''))
          else
            failed_creation(result.message || 'Sorry, something went wrong')
          end
        end
      rescue Exception => e
        failed_creation(e.to_s)
      end
    else
      create_new_user(params[:user])
    end
  end
  
  def show
    redirect_to authorization_error_path and return unless params[:id].to_i == current_user.id
    @user = current_user
  end

  def edit
    redirect_to authorization_error_path and return unless params[:id].to_i == current_user.id && current_user.authorized_for_update?
    @user = current_user
  end

  def update
    redirect_to authorization_error_path and return unless params[:id].to_i == current_user.id && current_user.authorized_for_update?
    @user = current_user
    redirect_to user_path(@user) and return if params[:cancel]
    if using_open_id?
      begin
        authenticate_with_open_id(params[:openid_url],
                                  :return_to => open_id_update_url,
                                  :optional => [:fullname],
                                  :required => [:nickname, :email]) do |result, identity_url, registration|
          if result.successful?
            update_user(:identity_url => identity_url,
                        :login => registration['nickname'],
                        :email => registration['email'],
                        :name => (registration['fullname'] || ''))
          else
            failed_update(result.message || 'Sorry, something went wrong')
          end
        end
      rescue Exception => e
        failed_update(e.to_s)
      end
    else
      update_user(:name => params[:user][:name],
                  :email => params[:user][:email])
    end
  end

  def change_password
    redirect_to authorization_error_path and return unless params[:id].to_i == current_user.id && current_user.authorized_for_update?
    @user = current_user
  end

  def update_password
    if request.put?
      redirect_to authorization_error_path and return unless params[:id].to_i == current_user.id && current_user.authorized_for_update?
      @user = current_user
      redirect_to user_path(@user) and return if params[:cancel]
      if User.authenticate(@user.login, params[:user][:current_password])
        if @user.update_attributes(:current_password => params[:user][:current_password],
                                   :password => params[:user][:password],
                                   :password_confirmation => params[:user][:password_confirmation])
          flash[:notice] = 'Password updated'
          redirect_to user_path(@user)
        else
          flash[:password_error] = if @user.errors.on(:password_confirmation)
                                     "Password confirmation #{[@user.errors.on(:password_confirmation)].flatten.first}"
                                   elsif @user.errors.on(:password)
                                     "Password #{[@user.errors.on(:password)].flatten.first}"
                                   end
          render :action => 'change_password'
        end
      else
        flash[:password_error] = 'Unable to authenticate. Make sure you type your current password correctly.'
        render :action => 'change_password'
      end
    end
  end

  protected
  
    def create_new_user(attributes)
      @user = User.new(attributes)
      success = @user && @user.save
    
      if success && @user.errors.empty?
        successful_creation(@user)
      else
        failed_creation
      end
    end
  
    def successful_creation(user)
      setup_user_session(user)
    end
  
    def failed_creation(message = 'Sorry, there was an error creating your account.')
      error_target = using_open_id? ? :openid_error : :account_error
      flash[error_target] = message
      @user = User.new unless @user
      render :action => :new
    end

    def update_user(params)
      if @user.update_attributes(params)
        flash[:notice] = 'Profile updated'
        redirect_to user_path(@user)
      else
        failed_update
      end
    end

    def failed_update(message = 'Sorry, there was a problem updating your profile.')
      flash[:profile_error] = message
      @user = current_user
      render :action => :edit
    end

end
