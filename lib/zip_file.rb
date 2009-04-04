# -*- coding: utf-8 -*-

require 'zip/zip'

module ZipFile

  def self.list(zipfile, verbose = false)
    files = []
    Zip::ZipFile::foreach(zipfile) {|entry|
      unless verbose
        files << entry.name
      else
        files << { :name => entry.name,
                   :size => entry.size,
                   :time => entry.time,
                   :type => entry.ftype }
      end
    }
    files
  end

end
