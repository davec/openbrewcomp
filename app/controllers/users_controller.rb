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
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    if request.put?
      redirect_to user_path and return if params[:cancel]
      @user = current_user
      if @user.update_attributes(:name => params[:user][:name],
                                 :email => params[:user][:email])
        flash[:notice] = 'Profile updated'
        redirect_to user_path
      else
        flash[:profile_error] = 'There was a problem updating your profile.'
        render :action => 'edit'
      end
    end
  end

  def change_password
    @user = current_user
  end

  def update_password
    if request.put?
      redirect_to user_path and return if params[:cancel]
      @user = current_user
      if User.authenticate(@user.login, params[:user][:current_password])
        if @user.update_attributes(:current_password => params[:user][:current_password],
                                   :password => params[:user][:password],
                                   :password_confirmation => params[:user][:password_confirmation])
          flash[:notice] = 'Password updated'
          redirect_to user_path
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
  
    def failed_creation(message = 'Sorry, there was an error creating your account')
      error_target = using_open_id? ? :openid_error : :account_error
      flash[error_target] = message
      @user = User.new unless @user
      render :action => :new
    end

end
