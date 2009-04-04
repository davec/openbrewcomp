module UrlWriterRetardaseInhibitor
  module ActionController
    def self.included(ac)
      ac.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def retardase_inhibitor
        begin
          request = self.request
          ::ActionController::UrlWriter.module_eval do
            @old_default_url_options = default_url_options.clone
            default_url_options[:host] = request.host
            default_url_options[:port] = request.port unless request.port == 80
            protocol = /(.*):\/\//.match(request.protocol)[1] if request.protocol.ends_with?("://")
            default_url_options[:protocol] = protocol
          end
          yield
        ensure
          ::ActionController::UrlWriter.module_eval do
            default_url_options[:host]     = @old_default_url_options[:host]
            default_url_options[:port]     = @old_default_url_options[:port] unless @old_default_url_options[:port].nil?
            default_url_options[:protocol] = @old_default_url_options[:protocol]
          end
        end
      end
    end
  end

  module ActionMailer
    def self.included(am)
      am.send(:include, ::ActionController::UrlWriter)
      ::ActionController::UrlWriter.module_eval do
        if ENV['RAILS_ENV'] == 'test'
          default_url_options[:host]     = 'test.host'
          default_url_options[:protocol] = 'http'
        else
          default_url_options[:host]     = 'localhost'
          # FIXME: +request+ is not accessible from here, but the lack of a
          # default port does not seem to be an issue so I'm just commenting
          # it out until I can figure out what the proper fix is.
          #default_url_options[:port]     = request.port == 80 ? nil : request.port
          default_url_options[:protocol] = 'http'
        end
      end
    end
  end
end
