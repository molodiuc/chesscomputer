require 'dm-core'
require 'dm-timestamps'
require 'dm-migrations'
require 'json'
require 'pgn'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://localhost/chess_archive_populated")

class Game
  include DataMapper::Resource
  
  property :id, Serial
  property :done, Boolean, :default => false
  property :metadata, Object
  timestamps :at

  has n, :positions

  def to_json
  	json_hash.to_json
  end

  def json_hash
  	{"done" => done, "game_id" => id, "created_at" => created_at, "updated_at" => updated_at}
  end
end

class Position
  include DataMapper::Resource
  
  property :id, Serial
  property :checked, Boolean, :default => false
  property :position_number, Integer
  property :is_boomerang, Boolean
  property :fen, Text
  property :moves, Object
  property :scores, Object
  property :depth, Integer
  property :etc, Object
  timestamps :at

  belongs_to :game

  def to_json
  	{"position_id" => id, "is_boomerang" => is_boomerang, "game" => game.json_hash, "moves" => moves, 
  	 "fen" => fen, "scores" => scores, "depth" => depth, "created_at" => created_at, "update_at" => updated_at}.to_json
  end

  def clean
    checked = false
    is_boomerang = nil
    moves = []
    scores = []
    depth = nil
    etc = nil
    save
  end

  def cp_difference
    normalized_scores.last - normalized_scores.first
  end

  def peak_score
    normalized_scores.max
  end

  def normalized_scores
    mult = boomerang_for(:white) ? 1 : -1
    scores.collect{|s| s.to_i * mult}
  end

  def boomerang_for player
    starting_position.player == player
  end

  def starting_position
    @starting_position ||= PGN::FEN.new(fen).to_position
  end

  def board_at move_num
    if @move_boards
      return @move_boards[move_num]
    end

    @move_boards = []
    
    current_position = starting_position
    moves.each do |m|
      current_position = current_position.move(m)
      @move_boards << current_position
    end

    return @move_baords[move_num]
  end

  def move_boards
    return @move_boards
  end

end

DataMapper.finalize