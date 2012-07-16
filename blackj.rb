# blackj.rb: Card, Deck, Hand, and Game classes to play a simple game of BlackJack to evolve the genetic algorithm
# Author: Eric Lang
# For more info: www.exyzzy.com

require'./gene'
#require 'profile'  # - this yields a wealth of information on where this code can use improving :-)

# Card class - suits and ranks
class Card
  
  def initialize (suit, rank)
    @suit = suit
    @rank = rank
    @suitText = ["Spades", "Hearts", "Clubs", "Diamonds"]
    @rankText = ["Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King"]
  end # initialize
  
  def suit
    @suit
  end
  
  def rank
    @rank
  end
  
  def to_s
    "#{@rank}, #{@suit}"
  end
  
  def pretty
    "  " + @rankText[@rank] + " of " + @suitText[@suit]
  end
  
end # Card

# Deck class - 52 
class Deck < Array
  @@suits = Array.new(4) {|i| i}
  @@ranks = Array.new(13) {|i| i}
  
  def initialize
    @@suits.each { |suit| @@ranks.each {|rank| self << Card.new(suit, rank)}}
    self.shuffle
  end # initialize

  def next
    @top = @top - 1
    if @top < 0
      self.shuffle!
      @top = 51
    end    
    self[@top]
  end # get
  
  def shuffle
    self.shuffle!
    @top = 52
  end # shuffle
  
end # Deck

# Hand class for dealer and player
# evaluates score of hand for blackjack
class Hand < Array
  def initialize(deck)
    @deck = deck
    @score = 0
    @aces = 0
    @showing = 0
  end # initialize
  
  def next
    self << @deck.next
    self.evaluate
  end # next
  
  def print
    self.each {|i| puts i.pretty}
  end # print
  
  def evaluate
    @score = 0
    @aces = 0
    t = 0
    sh = 0    #showing score, sorry, not yet into the whole ruby long variable names thing
    sha = 0   #showing aces
    self.each_index do |i| 
      ss = self.size - 1 - i 
      rank = self[ss].rank
      if rank == 0 then @aces += 1 end
      rp = rank + 1
      t = t + (rp < 10 ? rp : 10)
      if ss == 1
        sh = t
        sha = @aces
      end
    end #self.each
    (0...@aces).each do
      if t + 10 <= 21 then t = t + 10 end
    end
    @score = t
    (0...sha).each do
      if sh + 10 <= 21 then sh = sh + 10 end
    end
    @showing = sh
  end # evaluate


  def score
    @score
  end  
  
  def aces
    @aces
  end

  def showing
    @showing
  end
  
end # hand

# Game class - the blackjack game logic
class Game
  def initialize(genePool, cycles)
    @genePool = genePool
    @cycles = cycles
    @deck = Deck.new
  end

  def play(geneID)
    dealer = Hand.new(@deck)
    player = Hand.new(@deck)
    player.next
    dealer.next
    player.next
    dealer.next

    # puts "Dealer: #{dealer.score}, showing: #{dealer.showing}"
    # dealer.print
    # puts "Player: #{player.score}"
    # player.print

    if (dealer.score != 21) && (player.score != 21) then

      # deal to player
      done = false
      until done do
        if @genePool.result(geneID, [player.aces, player.score, dealer.showing]) == 1
        # if (player.score < 17) # - for dumb player baseline (.913)
          # puts "Player draws"
          player.next
          # puts player.last.pretty
          if player.score > 21 then
            done = true
          end          
        else
          done = true
        end
      end
    
      # deal to dealer
      if (player.score < 21) || ((player.score == 21) && (player.size > 2))then 
        done = false
        until done do
          if (dealer.score < 17) || ((dealer.score == 17) && (dealer.aces > 0))
            # puts "Dealer draws"
            dealer.next
            # puts dealer.last.pretty
          else
             done = true
          end
        end
      end
    end

    # Evaluate winner and player fitness score contribution
    # 0 for lose
    # 1 for push
    # 2 for win
    gamescore = 0
    # puts "Dealer: #{dealer.score} showing: #{dealer.showing}, Player #{player.score}"
    if ((dealer.score == 21) && (dealer.size == 2)) &&
        ((player.score == 21) && (player.size == 2)) then
      # puts "Double Blackjack, Push"
      gamescore = 1
    elsif (dealer.score == 21) && (dealer.size == 2) then
      # puts "Dealer Blackjack, Dealer wins"
      gamescore = 0
    elsif (player.score == 21) && (player.size == 2) then
      # puts "Player Blackjack, Player wins"
      gamescore = 2
    elsif player.score > 21 then 
      # puts "Player busted, Dealer wins"
      gamescore = 0
    elsif dealer.score > 21 then
      # puts "Dealer busted, Player wins"
      gamescore = 2
    elsif dealer.score == player.score then
      # puts "Push"
      gamescore = 1
    elsif dealer.score > player.score then
      # puts "Dealer wins"
      gamescore = 0
    else
      # puts "Player wins"
      gamescore = 2
    end      
    gamescore
  end # play

  # run all the cycles and determine gene fitness
  def fitness(geneID)
    # srand(0)        # for 'repeatable cards' per generation - but not really since all genes are different
    geneScore = 0
    @cycles.times do 
      geneScore += self.play(geneID)
    end
    # srand     # go back to random
    geneScore
  end # fitness

  #  this was an experiment to seed some genes at 'dumb player' level
  def headStart (inFields)              
    (2**inFields[0]).times do |i|
      (2**inFields[1]).times do |j|
        (2**inFields[2]).times do |k|
          index = @genePool.calcIndex([i, j, k])
          if j < 17
            @genePool.set(0, index, 1)
          else
            @genePool.set(0, index, 0)
          end
        end
      end
    end
    (@cycles/4).times do |i|
      @genePool[i+1].duplicate(@genePool[0])
    end
  end

end # Game


# for BlackJack there is:
# inField:
#     2 for player number of aces
#     5 for player total (including aces)
#     5 for dealer total showing
# outField:
#     1 player action (0 = stand, 1 = draw)
# gene = 2**12 * 1 = 4096 bits (each gene)
inFields = [2, 5, 5]    # 12 bits of input
outField = [1]          # 1 bit of output

cycles = 300            # play with this variable, or not - this is the number of hands played per generation to evaluate fitness
generations = 400       # play with this variable
genes = 500             # play with this variable
mutationRate =  0.0005  # play with this variable
crossoverRate =  0.9    # play with this variable

puts "Generations: #{generations}, Cycles: #{cycles}, Genes: #{genes}, Mutation: #{mutationRate}, Crossover: #{crossoverRate}"

# initialize genePool with random genes
genePool = GenePool.new(inFields, outField, genes, true)

# initialize mating pool with no genes
matingPool = GenePool.new(inFields, outField, 0, false)

# initial game to evaluate each gene
game = Game.new(genePool, cycles)

# game.headStart(inFields) # uncomment for headstart

puts "Generation, Average Fitness, Best Fitness"
puts "----------  ---------------, ------------"

# Main GA loop
generations.times do |g|  
  totalFitness = genePool.fitness(game)
  bestFit = genePool[genePool.bestFit].fitness
  puts "#{g}, %.4f, %.4f" % [((totalFitness.to_f/genePool.size.to_f) / cycles), (bestFit.to_f / cycles)]
  genePool.selection(matingPool, totalFitness)
  genePool.reproduction(matingPool, mutationRate, crossoverRate)
end



