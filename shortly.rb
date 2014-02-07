require 'sinatra'
require "sinatra/reloader" if development?
require 'active_record'
require 'digest/sha1'
require 'bcrypt'
require 'pry'
require 'uri'
require 'open-uri'
# require 'nokogiri'

###########################################################
# Configuration
###########################################################

enable :sessions

set :public_folder, File.dirname(__FILE__) + '/public'

configure :development, :production do
    ActiveRecord::Base.establish_connection(
       :adapter => 'sqlite3',
       :database =>  'db/dev.sqlite3.db'
     )
end

# Handle potential connection pool timeout issues
after do
    ActiveRecord::Base.connection.close
end

# turn off root element rendering in JSON
ActiveRecord::Base.include_root_in_json = false

###########################################################
# Models
###########################################################
# Models to Access the database through ActiveRecord.
# Define associations here if need be
# http://guides.rubyonrails.org/association_basics.html

class Link < ActiveRecord::Base
    has_many :clicks

    validates :url, presence: true

    before_save do |record|
        record.code = Digest::SHA1.hexdigest(url)[0,5]
    end
end

class Click < ActiveRecord::Base
    belongs_to :link, counter_cache: :visits
end

class User < ActiveRecord::Base
    def authenticate(password)
        self.password === BCrypt::Engine.hash_secret(password, self.salt)
    end

    before_create do |record|
        record.salt     = BCrypt::Engine.generate_salt
        record.password = BCrypt::Engine.hash_secret(record.password, record.salt)
        record.token    = Digest::SHA1.hexdigest record.to_s
    end
end

before '/' do
    halt redirect('/login') unless logged_in?
end

###########################################################
# Routes
###########################################################

['/', '/create'].each do |path|
    get path do
        erb :index
    end
end

get '/signup' do
    erb :signup
end

post '/signup' do
    # find by username
    user = User.find_by_username params[:username]
    unless user.nil?
        # redirect to /login
        redirect '/login'
    else
        # create account
        user = User.create params
        redirect '/'
    end
end

get '/login' do
    erb :login
end

post '/login' do
    user = User.find_by_username params[:username]
    if user.nil?
        redirect '/signup'
    else
        session[:identifier] = user.token if user.authenticate(params[:password])
        redirect '/'
    end
end

get '/logout' do
    session[:identifier] = nil
    redirect '/'
end

get '/links' do
    links = Link.order("created_at DESC")
    links.map { |link|
        link.as_json.merge(base_url: request.base_url)
    }.to_json
end

post '/links' do
    data = JSON.parse request.body.read
    uri = URI(data['url'])
    raise Sinatra::NotFound unless uri.absolute?
    link = Link.find_by_url(uri.to_s) ||
           Link.create( url: uri.to_s, title: get_url_title(uri) )
    link.as_json.merge(base_url: request.base_url).to_json
end

get '/:url' do
    link = Link.find_by_code params[:url]
    raise Sinatra::NotFound if link.nil?
    link.clicks.create!
    redirect link.url
end

###########################################################
# Utility
###########################################################

def read_url_head url
    head = ""
    url.open do |u|
        begin
            line = u.gets
            next  if line.nil?
            head += line
            break if line =~ /<\/head>/
        end until u.eof?
    end
    head + "</html>"
end

def get_url_title url
    # Nokogiri::HTML.parse( read_url_head url ).title
    result = read_url_head(url).match(/<title>(.*)<\/title>/)
    result.nil? ? "" : result[1]
end

def logged_in?
    !session[:identifier].nil?
end