require 'sanitize'
require 'sinatra'
require 'sinatra/cookies'

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
		@turn_name
	end

	def add_name(name)
		@to_do << name 
	end

	def guessed(card)
		@turn_done << card
		@done << card 
		@to_do.delete(card)
	end

	def new_card
		@to_do[rand(0..@to_do.length - 1)]
	end

	def new_round
		reset_passes
		reset_done
		@turn_done = []
	end

	def new_turn
		@passes.each { |name| @to_do << name }
		@passes = []
		@turn_done = []
		@turn_name = new_card
	end

	def no_names
		[@to_do, @done, @passes].all? {|states| states.empty?}
	end

	def pass(card)
		@passes << card 
		@to_do.delete(card)
	end

	def reset_done
		@done.each { |name| @to_do << name }
		@done = []
	end

	def reset_passes
		@passes.each { |name| @to_do << name }
		@passes = []
	end
end

def clean_input(input)
	sanitized_input = Sanitize.fragment(input)
	sanitized_input.delete!("/.$")
	sanitized_input[0..30] 
end

game = Game.new([],[])
names = {}

get '/' do
	erb :index
end

get '/add-names' do
	user_id = clean_input(cookies[:user_id])
	if names.keys.include?(user_id)
		puts names 
		erb :add_names, :locals => {:names => names[user_id]}
	else
		redirect to '/create-user'
	end
end

get '/create-user' do 
	user_id = rand(0..100).to_s 
	loop do 
		unless names.keys.include?(user_id)
			cookies[:user_id] = user_id
			names[user_id] = []
			break
		else
			user_id = rand(0..100).to_s
		end
	end
	redirect to('/add-names')
end

get '/empty' do 
	erb :empty, :locals => {:turn_done => game.turn_done, :no_names => game.no_names}
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

get '/name-added' do 
	erb :name_added
end

post '/new-name' do
	new_name = clean_input(params[:new_name])
	user_id = clean_input(cookies[:user_id]) 
	game.add_name(new_name)
	names[user_id] << new_name
	redirect to '/add-names'
end

get '/new-round' do 
	game.new_round
	redirect to '/'
end

get '/new-turn' do 
	if game.to_do.empty?
		redirect to '/empty'
	else
	game.new_turn
	redirect to '/turn'
	end
end

get '/next-player' do 
	game.reset_passes
	game.new_turn
	redirect to '/'
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

get '/reveal' do 
	erb :reveal, :locals => {:to_do => game.to_do, :done => game.done, :passes => game.passes}
end

get '/turn' do 
	erb :turn, :locals => {:current_name => game.turn_name, :passes => game.passes, :to_do => game.to_do, :turn_done => game.turn_done}
end
