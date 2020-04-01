require 'sinatra'

set :port, 8080
set :static, true
set :public_folder, "static"
set :views, "views"

class Game
	attr_reader :turn_name, :to_do, :done, :passes
	attr_writer :turn_name

	def initialize
		@to_do = ["Ajit Wadekar", "Emperor Go-Saga", "Sydney Newman", "Toshiro Mifune", "Gideon Gadot", "Samuel Alito", "Loris Kessel", "Daniel Paillé",  "John Abizaid", "Frederic Schwartz", "Annette O'Toole",  "Susan Boyle", "Samboy Lim", "Ding Junhui"]
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