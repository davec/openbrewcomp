xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
xml.rss "version" => "2.0" do
  xml.channel do
    xml.title @channel_name
    xml.link url_for(news_url)
    xml.pubDate CGI.rfc1123_date(@news_items.size > 0 ? @news_items.first.updated_at : Time.now)
    xml.description @channel_description
    xml.language "en-us"
    @news_items.each do |item|
      xml.item do
        xml.title item.title
        xml.link url_for(article_url(item))
        xml.description item.description_encoded
        xml.pubDate CGI.rfc1123_date(item.updated_at)
        xml.guid url_for(article_url(item))
        xml.author h(item.author.display_name)
      end
    end
  end
end
