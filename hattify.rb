require 'sanitize'
require 'sinatra'
require 'json'

USERNAME = ENV["HAT_GAME_USERNAME"]
PASSWORD = ENV["HAT_GAME_PASSWORD"]

set :port, 8080
set :static, true
set :public_folder, "static"
set :views, "views"

use Rack::Auth::Basic, "What's the password?" do |username, password|
  username == USERNAME and password == PASSWORD
end

class Game
	attr_reader :turn_name, :to_do, :done, :passes, :turn_done
	attr_writer :turn_name

	def initialize(to_do, done)
		@to_do = to_do
		@done = done
		@passes = []
		@turn_done = []
		@turn_name = new_card
	end

	def new_card
		@to_do[rand(0..@to_do.length - 1)]
	end

	def guessed(card)
		@turn_done << card
		@done << card 
		@to_do.delete(card)
	end

	def pass(card)
		@passes << card 
		@to_do.delete(card)
	end

	def reset_passes
		@passes.each { |name| @to_do << name }
		@passes = []
	end

	def reset_done
		@done.each { |name| @to_do << name }
		@done = []
	end

	def new_turn
		@passes.each { |name| @to_do << name }
		@passes = []
		@turn_done = []
		@turn_name = new_card
	end

	def new_round
		reset_passes
		reset_done
		@turn_done = []
	end

	def add_name(name)
		@to_do << name 
	end

end

def clean_input(input)
	sanitized_input = Sanitize.fragment(input)
	sanitized_input.delete!("/.$")
	sanitized_input[0..30] 
end

game = Game.new(["this is a name"],[])

get '/' do
	erb :index
end

get '/add-names' do
	erb :add_names
end

get '/new-turn' do 
	game.new_turn
	redirect to '/turn'
end

get '/turn' do 
	erb :turn, :locals => {:current_name => game.turn_name, :passes => game.passes, :to_do => game.to_do, :turn_done => game.turn_done}
end

get '/guessed' do
	game.guessed(game.turn_name)
	if game.to_do.empty?
		unless game.passes.empty?
			redirect to '/play-pass'
		else
			redirect to '/empty'
		end
	else
	game.turn_name = game.new_card
	redirect to '/turn'
	end
end

get '/pass' do 
	game.pass(game.turn_name)
	unless game.to_do.empty?
	game.turn_name = game.new_card
	redirect to '/turn'
	else redirect to '/empty'
	end
end

get '/play-pass' do 
	game.turn_name = game.passes[0]
	game.reset_passes
	redirect to '/turn'
end

get '/next-player' do 
	game.reset_passes
	game.new_turn
	redirect to '/'
end

get '/empty' do 
	erb :empty, :locals => {:turn_done => game.turn_done}
end

get '/new-round' do 
	game.new_round
	redirect to '/'
end

get '/reveal' do 
	erb :reveal, :locals => {:to_do => game.to_do, :done => game.done, :passes => game.passes}
end

get '/add-names' do
	erb :add_names
end

post '/new-name' do
	new_name = clean_input(params[:new_name])
	game.add_name(new_name)
	redirect to '/name-added'
end

get '/name-added' do 
	erb :name_added
end