class PasswordsController < ApplicationController
  before_filter :login_prohibited
  before_filter :set_action_mailer_options, :only => :create

  def new
    @password = Password.new
  end

  def create
    @password = Password.new(params[:password])
    @password.user = User.find_by_email_and_identity_url(@password.email, nil)
    
    if @password.save
      PasswordMailer.deliver_forgot_password(@password)
      flash[:notice] = "A link to change your password has been sent to #{@password.email}."
      redirect_to new_password_path
    else
      render :action => :new
    end
  end

  def reset
    begin
      @user = Password.find(:first, :conditions => ['reset_code = ? and expires_at > ?', params[:reset_code], Time.now]).user
    rescue
      flash[:notice] = 'The change password URL you visited is either invalid or expired.'
      redirect_to new_password_path
    end    
  end

  def update_after_forgetting
    @user = Password.find_by_reset_code(params[:reset_code]).user
    
    if @user.update_attributes(params[:user])
      flash[:notice] = 'Password was successfully updated.'
      redirect_to login_path
    else
      flash[:password_error] = if @user.errors.on(:password_confirmation)
                                 "Password confirmation #{[@user.errors.on(:password_confirmation)].flatten.first}"
                               elsif @user.errors.on(:password)
                                 "Password #{[@user.errors.on(:password)].flatten.first}"
                               end
      redirect_to :action => :reset, :reset_code => params[:reset_code]
    end
  end
  
end
