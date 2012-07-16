# oneMax.rb, to test the genetic algorithm
# Author: Eric Lang
# For more info: www.exyzzy.com

require'./gene'
#require 'profile'

# Game class - required
class Game
  def initialize(genePool)
    @genePool = genePool
  end

  # count bits in each gene for fitness
  def fitness(geneID)
    geneScore = 0
    @genePool[geneID].each_index do |i|
      geneScore += @genePool.get(geneID, i) 
    end
    geneScore
  end # fitness

end # Game


# for OneMax there will be:
# inField:
#     8 for gene with 256 bits
# outField:
#     1 the bit
# gene = 2**8 * 1 = 256 bits (each gene)

generations = 200
genes = 300
inFields = [8]
outField = [1]
mutationRate =  0.005
crossoverRate =  0.90
puts "One Max"
puts "Generations: #{generations}, Genes: #{genes}, Mutation: #{mutationRate}, Crossover: #{crossoverRate}"
# initialize genePool with random genes
genePool = GenePool.new(inFields, outField, genes, true)

# initialize mating pool with no genes
matingPool = GenePool.new(inFields, outField, 0, false)

# initial game to evaluate each gene
game = Game.new(genePool)

puts "Generation, Average Fitness, Best Fitness"
puts "----------  ---------------, ------------"

# Main GA loop
generations.times do |g|  
  totalFitness = genePool.fitness(game)
  bestFit = genePool[genePool.bestFit].fitness
  puts "#{g}, %.4f, %d, id: %d" % [(totalFitness.to_f/genePool.size.to_f), bestFit, genePool.bestFit]
  if bestFit == 256 then abort ("All done") end
  genePool.selection(matingPool, totalFitness)
  genePool.reproduction(matingPool, mutationRate, crossoverRate)
end

