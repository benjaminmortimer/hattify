require 'sinatra'

set :port, 8080
set :static, true
set :public_folder, "static"
set :views, "views"

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

end

names = ["Ajit Wadekar", "Emperor Go-Saga", "Sydney Newman", "Toshiro Mifune", "Gideon Gadot", "Samuel Alito", "Loris Kessel", "Daniel Paille",  "John Abizaid", "Frederic Schwartz", "Annette O'Toole",  "Susan Boyle", "Samboy Lim", "Ding Junhui"]
game = Game.new(names, [])

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