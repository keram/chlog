require 'net/http'
require 'net/https'
require 'open-uri'


class Changelog < Padrino::Application
  register Padrino::Rendering
  register Padrino::Helpers

  get '/' do
    render :index
  end

  get '/proxy' do
    result = ''

    begin
      url = params[:url].to_s.gsub(/\s/, '')
      uri = URI.parse(url)
      cfg = {}
      # bad bad bad
      cfg[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE if url =~ /^https/
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

      timeout(5) do
        response = open(uri, cfg)
        case
        when url =~ /\.(md|MD|txt)$/
          result = markdown.render(response.read)
        when response.content_type =~ /(rss|xml)/
          feed = FeedMe.parse response.read
          link = feed.url || feed.link
          result += %Q{<h2><a href="#{link}">#{strip_tags(feed.title)}</a></h2>}
          feed.entries.each do |entry|
            link = entry.url
            result += '<div>'
            result += %Q{<h3><a href="#{link}">#{strip_tags(entry.title)}</a></h3>}
            result += %Q{<div>#{markdown.render(strip_tags(entry.content || entry.description || ''))}</div>}
            result += '</div>'
          end
        else
          result = %Q{<iframe sandbox style="border: none; width: 100%; height: 50em;" src="#{url}"></iframe>}
        end
      end
    rescue
      result = $!.message
    end

    content_type 'text/plain;charset=utf8'
    render :erb, result, :layout => false
  end

  get '/sp' do
    result = ''
    begin
      url = params[:url].to_s.gsub(/\s/, '')

      conn = Faraday.new do |f|
        # f.response :logger
        f.adapter  Faraday.default_adapter
        f.headers = { }
      end

      response = conn.get do |req|
        req.url url
        req.options[:timeout] = 5
        req.options[:open_timeout] = 2
      end

      result = "initChangelog(#{strip_tags(response.body)});"
    rescue
      result = $!.message
    end

    result
  end

  # enable :sessions

  ##
  # Caching support
  #
  # register Padrino::Cache
  # enable :caching
  #
  # You can customize caching store engines:
  #
  #   set :cache, Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
  #   set :cache, Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1))
  #   set :cache, Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
  #   set :cache, Padrino::Cache::Store::Memory.new(50)
  #   set :cache, Padrino::Cache::Store::File.new(Padrino.root('tmp', app_name.to_s, 'cache')) # default choice
  #

  ##
  # Application configuration options
  #
  # set :raise_errors, true       # Raise exceptions (will stop application) (default for test)
  # set :dump_errors, true        # Exception backtraces are written to STDERR (default for production/development)
  # set :show_exceptions, true    # Shows a stack trace in browser (default for development)
  # set :logging, true            # Logging in STDOUT for development and file for production (default only for development)
  # set :public_folder, "foo/bar" # Location for static assets (default root/public)
  # set :reload, false            # Reload application files (default in development)
  # set :default_builder, "foo"   # Set a custom form builder (default 'StandardFormBuilder')
  # set :locale_path, "bar"       # Set path for I18n translations (default your_app/locales)
  # disable :sessions             # Disabled sessions by default (enable if needed)
  # disable :flash                # Disables sinatra-flash (enabled by default if Sinatra::Flash is defined)
  # layout  :my_layout            # Layout can be in views/layouts/foo.ext or views/foo.ext (default :application)
  #

  ##
  # You can configure for a specified environment like:
  #
  #   configure :development do
  #     set :foo, :bar
  #     disable :asset_stamp # no asset timestamping for dev
  #   end
  #

  ##
  # You can manage errors like:
  #
  #   error 404 do
  #     render 'errors/404'
  #   end
  #
  #   error 505 do
  #     render 'errors/505'
  #   end
  #
end
