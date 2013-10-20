require "rubygems"
require "bundler"
Bundler.require :development

Encoding.default_external = Encoding::UTF_8

def load_sprockets
  root = File.expand_path '../', __FILE__
  Sprockets::Environment.new(root).tap do |sprockets|
    %w(app vendor).each do |prefix|
      path = File.expand_path "../#{prefix}", __FILE__
      Dir["#{path}/*"].each do |subpath|
        dirname = File.basename subpath
        sprockets.append_path File.join path, dirname
      end
    end
  end
end

desc "Build assets (javascripts, stylesheets, images, ...)"
task "build:assets" do
  load_sprockets.tap do |sprockets|
    sprockets.each_logical_path do |logical_path|
      next unless logical_path =~ /\Aapplication.(js|css)\Z|\.(gif|jpeg|jpg|png)\Z/

      if asset = sprockets.find_asset(logical_path)
        path = File.join sprockets.root, 'www', 'assets', logical_path
        FileUtils.mkdir_p File.dirname path
        asset.write_to path
      end
    end
  end
end

desc "Build HAML views"
task "build:views:haml" do
  root = File.expand_path '../', __FILE__
  path = File.join root, "app", "views"
  Dir["#{path}/**/*.haml"].each do |haml_path|
    haml_logical_path = haml_path.sub path, ""
    html_logical_path = haml_logical_path.sub /(\.html)?\.haml\Z/, ".html"
    html_path = File.join root, "www", html_logical_path

    FileUtils.mkdir_p File.dirname html_path

    haml = File.read haml_path
    engine = Haml::Engine.new haml
    html = engine.render

    File.open html_path, 'w' do |html_file|
      html_file.write html
    end
  end
end

desc "Build views"
task "build:views" => "build:views:haml"

desc "Build everything"
task "build" => ["build:assets", "build:views"]

task "default" => "build"