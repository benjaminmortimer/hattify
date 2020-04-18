require 'sinatra'
require 'httparty'
require 'json'

TRELLO_API_KEY = ENV["TRELLO_API_KEY"]
TRELLO_API_TOKEN = ENV["TRELLO_API_TOKEN"]
TO_DO_CARD_ID = ENV["TO_DO_CARD_ID"]
DONE_CARD_ID = ENV["DONE_CARD_ID"]

set :port, 8080
set :static, true
set :public_folder, "static"
set :views, "views"

class TrelloClient
	def initialize(key, token)
		@key = key
		@token = token
		@trello_api_cards_url = 'https://api.trello.com/1/cards/'
		@auth_string = '?key=' + @key + '&token=' + @token
	end

	def read_card(card_id)
		url = @trello_api_cards_url + card_id + @auth_string
		desc = JSON.parse(HTTParty.get(url).body)['desc']
	end

	def write_card(card_id, new_content)
		new_content_param = '&desc=' + new_content
		HTTParty.put(@trello_api_cards_url + card_id + @auth_string + new_content_param)
	end

	def read_to_do
		read_card(TO_DO_CARD_ID).split(',')
	end

	def read_done
		read_card(DONE_CARD_ID).split(',')
	end

	def save_to_do(to_do_array)
		write_card(TO_DO_CARD_ID, to_do_array.join(','))
	end

	def save_done(done_array)
		write_card(DONE_CARD_ID, done_array.join(','))
	end
end

fbkjdfgbkjgdfz

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

	def save_to_do
		to_do.join(',') 
	end

	def save_done
		done.join(',')
	end

	def reload(to_do, done)
		@to_do = to_do
		@done = done 
	end

end

trello_client = TrelloClient.new(TRELLO_API_KEY, TRELLO_API_TOKEN)
game = Game.new(trello_client.read_to_do, [])

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
	trello_client.save_to_do(game.to_do)
	trello_client.save_done(game.done)
	game.new_turn
	game.reload(trello_client.read_to_do, trello_client.read_done)
	redirect to '/'
end

get '/empty' do 
	erb :empty, :locals => {:turn_done => game.turn_done}
end

get '/new-round' do 
	game.new_round
	trello_client.save_to_do(game.to_do)
	trello_client.save_done(game.done)
	redirect to '/'
end

get '/reveal' do 
	erb :reveal, :locals => {:to_do => game.to_do, :done => game.done, :passes => game.passes}
end