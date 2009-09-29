# -*- coding: utf-8 -*-

# Original code found at http://www.scottmoe.info/2008/10/12/cap-deploy-web-disable-and-phusion-passenger

module MaintenanceMode

  protected

    def disabled?
      require 'nokogiri'

      maintfile = "#{RAILS_ROOT}/public/system/maintenance.html"
      if FileTest::exist?(maintfile)
        respond_to do |format|
          format.html {
            send_file(maintfile,
                      :type => 'text/html; charset=utf-8',
                      :disposition => 'inline',
                      :status => '503 Service Unavailable')
          }
          format.js {
            doc = Nokogiri::HTML(open(maintfile))
            send_data(doc.xpath("//p").collect{|e| e.inner_html.squish}.join("\n\n"),
                      :type => 'text/plain; charset=utf-8',
                      :status => '503 Service Unavailable')
          }
        end
        @performed_render = true
      end
    end

end
