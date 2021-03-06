require "./AI2048/*"
require "option_parser"

total = 1000
block = 1000
player_args = ""
evil_args = ""
save = ""
summary = false

OptionParser.parse! do |parser|
  parser.banner = "Usage: AI2048 [arguments]"
  parser.on("--total=TOTAL_GAMES", "Indicate how many games to play") { |n| total = n.to_i }
  parser.on("--block=BLOCK", "...") { |n| block = n.to_i }
  parser.on("--play=PLAYER_ARGS", "The arguments of player initialization") { |args| player_args = args }
  parser.on("--evil=EVIL_ARGS", "The arguments of evil (environment) initialization") { |args| evil_args = args }
  # parser.on("--load=LOAD", "Specifies the name to salute") { |name| load = name }
  parser.on("--save=SAVE", "Path to save statistic data") { |path| save = path }
  # parser.on("--summary", "Specifies the name to salute") { summary = true }
  parser.on("-h", "--help", "Show this help") { puts parser }
end

# player = Player.new player_args
evil = RandomEnvironment.new evil_args
ai_aco = AIACO.new "ant_num=10"
# ai_td = AITD.new ""

stat = Statistic.new(total, block)

stat.run_until_finished do
  open_episode do
    game_prev_prev_state = Board.new
    game_prev_state = Board.new
    game = Board.new
    r = 0
    mov_op = -1

    score = 0
    loop do
      who = take_turns(ai_aco, evil)
      # who = take_turns(ai_td, evil)
      action = who.take_action(game)

      if who != evil
        game_prev_prev_state = game
        mov_op = action.to_i
      end

      delta_score = action.apply!(pointerof(game))
      break if delta_score == -1

      if who != evil
        game_prev_state = game
        r = delta_score
      else
        ai_aco.learning game_prev_prev_state.to_slice, mov_op, r, game_prev_state.to_slice, game.to_slice
      end

      save_action(action)
      ai_aco.save_action(action)
      score += delta_score
    end
    # winner = last_turns(ai_td, evil)
    winner = last_turns(ai_aco, evil)
    ai_aco.update_pheromons(score)
  end
end

if !save.empty?
  File.open(save, "w") do |f|
    stat.log(f)
    f.flush
  end
end
