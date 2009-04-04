# -*- coding: utf-8 -*-

class Admin::ExportsController < AdministrationController

  def index
    respond_to do |format|
      format.html
      format.csv do
        # Create a CSV export file containing tables from the listed models.
        # Must specify conversion to CP1252 charset since Excel does not
        # handle UTF-8 very well, if at all.
        export = Export.new([ :country, :region, :club, :carbonation, :sweetness, :strength, :category, :award, :style, :entrant, :entry ],
                            { :format => :csv, :convert => 'CP1252//TRANSLIT' })
        send_to_client(export)
      end
      format.yaml do
        # Create a YAML export file containing tables from all models.
        export = Export.new('*', { :format => :yml })
        send_to_client(export)
      end
    end
  end

  private

    def send_to_client(export)
      # Send the data, not the file.  If we use send_file, there's a slight
      # possibility that the data file will be deleted before it can be sent.
      # Slurping the file's contents into memory shouldn't be a problem since
      # the data files we're working with are relatively small (<50KB).
      send_data(export.data, :filename => export.name, :type => export.type)
      #send_file(export.file, :filename => export.name, :type => export.type)
    end

end
