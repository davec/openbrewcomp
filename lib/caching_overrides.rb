# -*- coding: utf-8 -*-

# Override fragment_cache_key to blank out the host name so instead of
# caching different fragments as, for example, example.com/fragment/data
# and www.example.com/fragment/data, the fragment will be cached as
# fragment/data.
ActionController::Caching::Fragments.module_eval do
  def fragment_cache_key(name)
    name.is_a?(Hash) ? url_for(name.merge(:host=>"")).split(":///").last : name
  end
end

# Strip the host name from the cache path for action caches.
ActionController::Caching::Actions::ActionCachePath.class_eval do
  def path
    return @path if @path
    @path = controller.url_for(options.merge(:host=>"")).split(":///").last
    normalize!
    add_extension!
    URI.unescape(@path)
  end
end
