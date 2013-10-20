require "rubygems"
require "bundler/setup"

Bundler.require

Dotenv.load

$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))

require "application"

map("/assets") { run Application.assets }
map("/jsonrpc") { run Rack::Proxy.new(backend: "#{ENV["XBMC_HOST"] || "localhost:8080"}/jsonrpc") }
map("/") { run Application }
