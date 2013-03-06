APP_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

require 'rubygems'
require 'sinatra'
require 'koala'

# register your app at facebook to get those infos
# your app id
APP_ID     = ENV['FB_APP_ID']

# your app secret
APP_SECRET = ENV['FB_APP_SECRET']

# set your app site url
# don't forget to add your IP to the app's whitelist on facebook
SITE_URL   = ENV['APP_SITE_URL']

class FBMon < Sinatra::Application

	include Koala

	set :root, APP_ROOT
	use Rack::Session::Cookie, secret: 'PUT_A_GOOD_SECRET_IN_HERE'

    def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ["admin","admin"]
    end

    def protected!
        unless authorized?
            response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
            throw(:halt, [401, "Oops... we need your login name & password\n"])
        end
    end


	get '/' do
		if session['access_token']
		  'You are logged in! <a href="/logout">Logout</a>'
			# do some stuff with facebook here
			# for example:
			# @graph = Koala::Facebook::GraphAPI.new(session["access_token"])
			# publish to your wall (if you have the permissions)
			# @graph.put_wall_post("I'm posting from my new cool app!")
			# or publish to someone else (if you have the permissions too ;) )
			# @graph.put_wall_post("Checkout my new cool app!", {}, "someoneelse's id")
		else
			'<a href="/fbauth">Auth</a>'
		end
	end

	get '/fbauth' do
        protected!
		# generate a new oauth object with your app data and your callback url
		session['oauth'] = Facebook::OAuth.new(APP_ID, APP_SECRET, SITE_URL + 'callback')
		# redirect to facebook to get your code
		redirect session['oauth'].url_for_oauth_code()
	end

	get '/logout' do
		session['oauth'] = nil
		session['access_token'] = nil
		redirect '/'
	end

	#method to handle the redirect from facebook back to you
	get '/callback' do
		#get the access token from facebook with your code
		session['access_token'] = session['oauth'].get_access_token(params[:code])
		redirect '/'
	end

end

