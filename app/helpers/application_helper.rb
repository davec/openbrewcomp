# -*- coding: utf-8 -*-

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include ActionView::Helpers::AssetTagHelper

  def page_title_tag
    "<title>#{page_title}</title>"
  end

  def page_header_tag
    "<h1>#{@page_header || page_title}</h1>" unless @suppress_page_header
  end

  def meta_description_tag
    %Q{<meta name="description" content="#{@page_description}" />} if @page_description
  end

  # Computes the path to a document asset in the public docs directory.
  # Similar to image_path but for files, primarily PDFs.
  #
  #   doc_path("file.pdf")  # => /docs/file.pdf
  #   doc_path("archived/file.pdf")  # => /docs/archived/file.pdf
  #   doc_path("/archived/file.pdf")  # => /archived/file.pdf
  def doc_path(source)
    # HACK: Get the path as for an image and change the directory.
    # TODO: Extend AssetTagHelper with a DocAsset module.
    image_path(source).sub('/images/', '/docs/')
  end

  # Computes the file size, in kilobytes, of the specified file asset in the public directory.
  # The reported size is rounded up to the nearest integer size.
  def file_size_in_kb(source)
    byte_size = file_size(source)
    kb_size = Kernel.Float(byte_size / 1.0.kilobyte).ceil
    "#{kb_size} KB"
  rescue
    "unknown size"
  end

  # Computes the file size, in megabytes, of the specified file asset in the public directory.
  # The reported size is rounded to the nearest .1 MB.
  def file_size_in_mb(source)
    byte_size = file_size(source)
    mb_size = Kernel.Float(byte_size / 0.1.megabyte).round / 10.0
    "%.1f MB" % mb_size
  rescue
    "unknown size"
  end

  # Computes the file size, in bytes, of the specified file asset in the public directory.
  # If an asset ID is included, which is defined to be anything following the
  # last (and only) '?', it it exists, in the path, it is first removed.
  def file_size(source)
    source = source.sub(Regexp.new("^#{ActionController::Base.asset_host}#{ActionController::Base.relative_url_root}"), "")
    filename = "#{RAILS_ROOT}/public/#{source.split('?').first}"
    size = File.stat(filename).size
  rescue
    logger.error "[ERROR] Cannot stat #{filename}"
    "unknown"
  else
    #logger.info "[INFO] Size of #{filename} in bytes: #{size}"
    size
  end

  def pdf_icon
    image_tag 'pdficon_small.gif', :class => 'icon', :alt => '(PDF Format)', :title => 'PDF File', :size => '17x17'
  end

  def ps_gz_icon
    image_tag 'psgzicon_small.gif', :class => 'icon', :alt => '(GZipped PostScript Format)', :title => 'GZipped PostScript File', :size => '17x17'
  end

  def link_to_with_icon(name, target = {}, options = {})
    icon = ''
    include_size = options.delete(:size)
    extname = options.delete(:extname)
    extname = File.extname(target) if extname.nil? && target.is_a?(String)
    unless extname.nil?
      icon_method = "#{extname.sub(/^\.([^\?]*)(\?.*)?/, '\1')}_icon".gsub('.','_')
      icon = self.respond_to?(icon_method) ? self.send(icon_method) : ''
    end
    returning String.new do |str|
      str << link_to(name, target, options)
      str << icon
      str << "&nbsp;(#{file_size_in_kb(target)})" if include_size && target.is_a?(String)
    end
  end

  def nav_class_for(path)
    paths = [path].flatten

    v = paths.any?{|p|
      if p =~ /\Ahttps?:\/\/.+\z/
        current_page?(p)
      elsif p[-1,1] == '/'
        controller.controller_path.starts_with?(p)
      else
        controller.controller_path == p
      end
    }
    %Q{class="#{v ? 'on' : 'off'}"}
  end

  private

    def page_title
      @page_title || competition_name
    end
  
end
