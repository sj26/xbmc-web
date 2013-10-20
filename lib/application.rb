require "active_support/all"
require "sinatra/reloader"

require "slim"
require "skim"

Encoding.default_external = Encoding::UTF_8

Skim::Engine.default_options[:use_asset] = true

class Application < Sinatra::Base
  set :root, File.expand_path('../../', __FILE__)
  set :assets, Sprockets::Environment.new(root)
  set :assets_precompile, [/\A(?!.*\.(?:js|css)).*\Z/, /application.(css|js)$/]
  set :assets_prefix, "assets"
  set :assets_path, File.join(root, "public", assets_prefix)
  set :views, File.join(root, "app", "views")

  configure :development do
    register Sinatra::Reloader
  end

  configure do
    Dir["#{root}/{vendor,lib,app}/assets/*"].each do |path|
      assets.append_path path
    end
    assets.context_class.send(:include, Module.new do
      def asset_path(source, options={})
        tail, source = source[/([\?#].+)$/], source.sub(/([\?#].+)$/, '')
        "/assets/#{environment.find_asset(source).digest_path}#{tail}"
      end
    end)
  end

  helpers do
    def asset_path(source, options={})
      tail, source = source[/([\?#].+)$/], source.sub(/([\?#].+)$/, '')
      "/assets/#{settings.assets.find_asset(source).digest_path}#{tail}"
    end
  end

  get "/" do
    slim :index
  end
end
