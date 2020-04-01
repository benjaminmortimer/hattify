require 'sinatra'

set :port, 8080
set :static, true
set :public_folder, "static"
set :views, "views"

class Game
	attr_reader :turn_name, :to_do, :done, :passes
	attr_writer :turn_name

	def initialize
		@to_do = ["Ajit Wadekar", "Emperor Go-Saga", "Sydney Newman", "Toshiro Mifune", "Gideon Gadot"]
		@done = []
		@passes = []
		@turn_name = new_card
	end

	def new_card
		@to_do[rand(0..@to_do.length - 1)]
	end

	def new_turn_name
		@turn_name = new_card
	end

	def guessed(card)
		@done << card 
		@to_do.delete(card)
	end

	def pass(card)
		@pass << card 
	end
end

game = Game.new

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

get '/empty' do 
	erb :empty
end

get '/new-round' do 
	game.done.each { |name| game.to_do << name }
	game.passes.each { |name| game.to_do << name }
	redirect to '/'
end

get '/reveal' do 
	erb :reveal, :locals => {:to_do => game.to_do, :done => game.done, :passes => game.passes}
end