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
end

class Game
	attr_reader :turn_name, :to_do, :done, :passes
	attr_writer :turn_name

	def initialize(to_do)
		@to_do = to_do
		@done = []
		@passes = []
		@turn_name = new_card
	end

	def new_card
		@to_do[rand(0..@to_do.length - 1)]
	end

	def guessed(card)
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

	def save_to_do
		to_do.join(',') 
	end

	def save_done
		done.join(',')
	end

end


trello_client = TrelloClient.new(TRELLO_API_KEY, TRELLO_API_TOKEN)
game = Game.new(trello_client.read_to_do)

get '/' do
	erb :index
end

get '/turn' do 
	erb :turn, :locals => {:current_name => game.turn_name}
end

get '/guessed' do
	game.guessed(game.turn_name)
	unless game.to_do.empty?
	game.turn_name = game.new_card
	redirect to '/turn'
	else redirect to '/empty'
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

get '/next-player' do 
	game.reset_passes
	trello_client.write_card(TO_DO_CARD_ID, game.save_to_do)
	trello_client.write_card(DONE_CARD_ID, game.save_done)
	redirect to '/'
end

get '/empty' do 
	erb :empty
end

get '/new-round' do 
	game.reset_passes
	game.reset_done
	redirect to '/'
end

get '/reveal' do 
	erb :reveal, :locals => {:to_do => game.to_do, :done => game.done, :passes => game.passes}
end