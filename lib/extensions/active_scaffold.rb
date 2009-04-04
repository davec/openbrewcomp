# -*- coding: utf-8 -*-

module ActiveRecordPermissions::Permissions::ClassMethods
  # Patch authorized_for? to deal gracefully with singletons,
  # referencing self.instance if self.new raises a NoMethodError.
  def authorized_for?(*args)
    @authorized_for_delegatee ||= begin
                                    self.new
                                  rescue NoMethodError
                                    self.instance
                                  rescue Exception => e
                                    raise e
                                  end
    @authorized_for_delegatee.authorized_for?(*args)
  end
end

# module ActiveScaffold::Config
#   class Core < Base
#     def label
#       as_(@label) || model.table_name.humanize.titleize
#   end
# end

module ActiveScaffold::Helpers::ViewHelpers
  # Modify active_scaffold_includes to cache the JS files, if caching is enabled
  def active_scaffold_includes(frontend = :default, options = {})
    cache = options.stringify_keys["cache"]
    javascripts = active_scaffold_javascripts(frontend)
    javascripts << { :cache => (cache == true ? "active_scaffold_#{frontend}" : cache) } if ActionController::Base.perform_caching && cache
    js = javascript_include_tag(*javascripts)

    css = stylesheet_link_tag(ActiveScaffold::Config::Core.asset_path("stylesheet.css", frontend))
    ie_css = stylesheet_link_tag(ActiveScaffold::Config::Core.asset_path("stylesheet-ie.css", frontend))

    js + "\n" + css + "\n<!--[if IE]>" + ie_css + "<![endif]-->\n"
  end
end

