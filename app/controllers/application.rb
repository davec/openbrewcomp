# -*- coding: utf-8 -*-

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'date'

class ApplicationController < ActionController::Base
  include MaintenanceMode
  before_filter :disabled?

  include ExceptionNotifiable
  include AuthenticatedSystem

  include DatabaseAbstractions

  unless ActionController::Base.consider_all_requests_local
    rescue_from ActiveRecord::RecordNotFound,
                ActionController::RoutingError,
                ActionController::UnknownController,
                ActionController::UnknownAction,
                RuntimeError,
                :with => :dispatch_error
    rescue_from ActionController::InvalidAuthenticityToken,
                :with => :redirect_to_login_after_expired_session
    rescue_from ActionController::RedirectBackError do |exception|
      redirect_to root_path
    end
  end

  begin
    # See ActionController::RequestForgeryProtection for details
    # Comment the :secret if you're using the cookie session store
    protect_from_forgery :secret => APP_CONFIG[:forgery_protect_key]
  rescue Exception => e
    # The only valid scenario that allows us to get here is when running rake.
    raise e unless File.basename($0) == 'rake'
  end

  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password

  helper :results
  helper :styles

  protected

    def competition_data
      CompetitionData.instance
    end

    def competition_name
      competition_data.name
    end
    helper_method :competition_data, :competition_name

    def is_registration_open?
      competition_data.is_registration_open?
    end

    def render_pdf(filename, options = {})
      basename = File.basename(filename, '.*')
      rtex_options = options.merge({ :filename => "#{basename}.pdf",
                                     :layout => false })
      rtex_options.merge!({ :debug => true,
                            :shell_redirect => "> #{RAILS_ROOT}/tmp/#{basename}.rtex.log 2>&1" }) if ENV['RAILS_ENV'] == 'development'

      render rtex_options
    end

    def geocode_ip
      session[:geocode_ip] ||= begin
        location = IpGeocoder.geocode(request.remote_ip)
        location.success ? location : nil
      end
    end

    # Get the region from the specified geolocation (as returned by geocode_ip)
    # constrained by the selectable countries (i.e., if +geolocation+ specifies
    # a country that is not selectable, no region is returned).
    def get_region_from(geolocation)
      Region.find_by_sql(['SELECT * FROM regions WHERE region_code = ? AND country_id = (SELECT id FROM countries WHERE country_code = ? AND is_selectable = ?)',
                         geolocation.state, geolocation.country_code, true]).first
    end

  private

    def setup_user_session(user)
      session[:previous_login] = user.last_logon_at
      user.last_logon_at = Time.now.utc

      self.current_user = user
      default_page = if user.is_admin?
                       admin_path
                     elsif is_registration_open?
                       online_registration_path
                     else
                       root_path
                     end
      redirect_back_or_default(default_page)
    end

    def browser_timezone_offset
      return nil if cookies[:TZ].blank?
      cookies[:TZ].to_i rescue nil
    end

    # Handle errors we rescue_from
    def dispatch_error(exception)
      render_error interpret_status(response_code_for_rescue(exception))
    end

    # Handle errors we don't rescue_from
    def rescue_action_in_public(exception)
      respond_to do |format|
        format.html {
          super exception
        }
        format.js {
          render_error interpret_status(response_code_for_rescue(exception))
        }
      end
    end

    def rescue_action_locally(exception)
      respond_to do |format|
        format.html {
          super exception
        }
        format.js {
          render_error interpret_status(response_code_for_rescue(exception))
        }
      end
    end

    def render_error(status = nil)
      respond_to do |format|
        format.html {
          render :template => "#{hash_for_error_url[:controller]}/#{hash_for_error_url[:action]}"
        }
        format.js {
          if status.nil?
            render(:text => 'Page not found', :status => 404)
          else
            code, error = status.split(' ', 2)
            render(:text => error, :status => code)
          end
        }
      end
    end

    def access_denied
      flash[:request_url] = request.url  # Save the requested URL
      redirect_to authorization_error_path and return false if logged_in?
      super
    end

    def redirect_to_error
      flash[:request_url] = request.url  # Save the requested URL
      redirect_to not_found_error_path
    end

    def redirect_to_login_after_expired_session
      flash[:login_error] = 'Your session has expired. Please log in again.'
      respond_to do |format|
        format.html { redirect_to(login_url) }
        format.js do
          render :update do |page|
            page.redirect_to(login_url)
          end
        end
      end
    end

end
