# -*- coding: utf-8 -*-

# Original code found at http://www.scottmoe.info/2008/10/12/cap-deploy-web-disable-and-phusion-passenger

module MaintenanceMode

  protected

    def disabled?
      require 'rexml/document'

      maintfile = "#{RAILS_ROOT}/public/system/maintenance.html"
      if FileTest::exist?(maintfile)
        response_type = 'text/html; charset=utf-8'
        response_status = '503 Service Unavailable'

        respond_to do |format|
          format.html do
            send_file(maintfile,
                      :disposition => 'inline',
                      :type => response_type,
                      :status => response_status)
          end
          format.js do
            doc = REXML::Document.new(open(maintfile))
            send_data(doc.elements.collect("//p"){|e| e.text.squish}.join("\n\n"),
                      :type => response_type,
                      :status => response_status)
          end
        end
        @performed_render = true
      end
    end

end
