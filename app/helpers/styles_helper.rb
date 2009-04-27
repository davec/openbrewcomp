# -*- coding: utf-8 -*-

module StylesHelper

  def create_description_link(link, description_url)
    if description_url =~ %r{\A(ftp|https?)://}
      external_link = description_url
    else
      parts = description_url.split('/').delete_if{|a| a.empty?}
      # If the URL is terminated by a / no action should be specified
      action = parts.pop unless description_url[-1,1] == '/'

      options = { :controller => "/#{parts.join('/')}" }
      options[:action] = action unless action.nil?
    end
    link_to(h(link), external_link || options)
  end

  def special_styles
    Style.all(:conditions => 'bjcp_category > 28',
              :order => 'bjcp_category')
  end

  def styles_with_required_styleinfo
    Style.all(:conditions => [ 'styleinfo = ?', StyleInfo::REQUIRED_KEY ],
              :order => 'bjcp_category, bjcp_subcategory')
  end

end
