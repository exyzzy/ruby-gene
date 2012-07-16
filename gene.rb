# gene.rb Class for implementing Genetic Algorithms in Ruby
# Author: Eric Lang
# For more info: www.exyzzy.com

require './bits'

# Gene extends the Bits class to add fitness
class Gene < Bits
  attr_accessor :fitness 

  def initialize (size)
    super(size)
    @fitness = 0      
  end

  def print
    super
    puts "  fitness: #{@fitness}"
  end

end

# GenePool is a collection of Genes
class GenePool
  attr_accessor :size

  # Initialize the gene pool 
  # inMask is an array of bit field sizes that express the input
  # outMask is the number of bits for each result
  # inMask and outMask are used to calculate the size of each gene
  # and to calculate the index of a gene for retrieval
  # Each gene is length 2**(sum of inMask) * (sum of outMask)
  # size is the number of genes in the genePool
  def initialize (inMask, outMask, size, randomize)
    @wordBits = 0.size * 8            # size of a word on your machine
    @inMask = inMask
    @outMask = outMask
    @size = size                      # number of genes
    @inLen = @inMask.inject(0, :+)    # sum the bits
    @outLen = @outMask.inject(0, :+)  # sum the bits

    @geneLen = 2**@inLen * @outLen     # length of gene needed for solution
    @bestGene = 0
    @bestFitness = 0      
    @genePool = []
    # allocate the genepool and seed it with random bits
    @size.times do |i|
      @genePool[i] = Gene.new(@geneLen)
      if randomize
        @genePool[i].numWords.times do |j|
          @genePool[i].setWord(j, rand(@genePool[i].wordMax))
        end
      end
    end
  end

  # clear the gene pool to 0 genes
  def clear
    @genePool.clear
    @size = 0
  end

  # add a new gene to a gene pool
  def add (geneBits)
    @genePool[@size] = Gene.new(@geneLen)
    @genePool[@size].duplicate(geneBits)
    @genePool[@size].fitness = geneBits.fitness
    @size += 1
  end

  # get a gene
  def [](index)
    @genePool[index]
  end

  # indexed gene crossover
  # Crosses bottom part of genA with bottom part of geneB
  # all bits below index
  def cross(geneAID, geneBID, index)
    temp = Bits.new(@geneLen)
    temp.duplicate(@genePool[geneAID])
    w = index/@wordBits
    w.times do |i|
      wtemp = @genePool[geneAID].getWord(i)
      @genePool[geneAID].setWord(i, @genePool[geneBID].getWord(i))
      @genePool[geneBID].setWord(i, wtemp)
    end
    start = w * @wordBits
    numBits = index - start
 
    @genePool[geneAID].set(start, numBits, @genePool[geneBID].get(start, numBits))
    @genePool[geneBID].set(start, numBits, temp.get(start, numBits))
  end

  # direct gene crossover
  def crossover(geneA, geneB, index)
    temp = Bits.new(geneA.size)
    temp.duplicate(geneA)
    w = index/@wordBits
    w.times do |i|
      wtemp = geneA.getWord(i)
      geneA.setWord(i, geneB.getWord(i))
      geneB.setWord(i, wtemp)
    end
    start = w * @wordBits
    numBits = index - start
 
    geneA.set(start, numBits, geneB.get(start, numBits))
    geneB.set(start, numBits, temp.get(start, numBits))
  end

  # direct gene mutation
  def mutate(gene, rate)
    gene.each_index do |i|
      if rand < rate
        gene.flip(i)
      end
    end
  end

  # print all genes in the pool
  def print
    @genePool.each_index do |i|
      puts "Gene #{i}:"
      @genePool[i].print
    end
  end

  # indexed gene set
  def set(geneID, index, value)
    a = @genePool[geneID]
    a[index] = value
  end

  # indexed gene get
  def get(geneID, index)
    a = @genePool[geneID]
    a[index]
  end

  # indexed gene multi-bit set
  def setMult(geneID, index, numBits, value)
    a = @genePool[geneID]
    a.set(index, numBits, value)
  end

  # indexed gene multi-bit get
  def getMult(geneID, index, numBits)
    a = @genePool[geneID]
    a.get(index, numBits)
  end

  def each(&block)
    @size.times { |index| yield self[index]}
  end

  def each_index(&block)
    @size.times { |index| yield index }
  end

  # compute index from multiple inFields
  def calcIndex(inFields)
    index = 0
    field = 0
    @inMask.each_index do |i|
      index += inFields[i] << field
      field += @inMask[i] 
    end
    index
  end

  # return a single bit result based on a multiple inFields
  def result(geneID, inFields)
    self.get(geneID, calcIndex(inFields))
  end

  # Fitness: calculate initial fitness for each gene
  def fitness(game)
    totalFitness = 0
    @bestFitness = 0
    @bestGene = 0
    @genePool.each_index do |geneID|
      fitness = game.fitness(geneID)
      @genePool[geneID].fitness = fitness
      if fitness > @bestFitness
        @bestGene = geneID
        @bestFitness = fitness
      end
      totalFitness += @genePool[geneID].fitness
    end
    totalFitness
  end

  def bestFit
    @bestGene
  end

  # Selection: create initial mating pool, roulette weighted
  def selection(matingPool, totalFitness)
    matingPool.clear
    # elitism in matingPool 0
    matingPool.add(@genePool[@bestGene])
    # create roulette wheel
    @genePool.each_index do |geneID|
      fraction = @genePool[geneID].fitness.to_f / totalFitness.to_f
      n = (fraction * @genePool.size).to_i
      n.times do
        matingPool.add(@genePool[geneID]) 
      end
    end
  end

  # Reproduction: cross and mutate
  def reproduction(matingPool, mutationRate, crossoverRate)
    mom = Gene.new(@genePool[1].size)
    dad = Gene.new(@genePool[1].size)
    @genePool.each_index do |geneID|
      m = rand(matingPool.size)
      d = rand(matingPool.size)
      mom.duplicate(matingPool[m])
      if rand < crossoverRate
        dad.duplicate(matingPool[d])
       index = rand(mom.size)
       self.crossover(mom, dad, index)
     end
      self.mutate(mom, mutationRate)
      @genePool[geneID].duplicate(mom)
    end
    # replace genePool 0 with best scoring gene (elitism)
    @genePool[0].duplicate(matingPool[0])
  end

end # GenePool


def test
  puts "NOW IN BITS------"
  myBits = Bits.new(128)
  myNew = Bits.new(128)
  myBits[5] = 1
  myBits[7] = 1
  myBits[0] = 1
  myBits.set(100, 3, 5)
  puts "myBits 0, 5, 7 on"
  myBits.print
  myBits[5] = 0
  puts "myBits[5] = 0"
  myBits.print
  myNew.duplicate(myBits)
  puts "myNew duplicate"
  myNew.print
  myNew.flip(5)
  puts "myNew flipped(5)"
  myNew.print
  myBits[17] = 1
  puts "myBits[17] = 1"
  myBits.print
  myNew[9] = 1
  puts "myNew[9] = 1"
  myNew.print
  puts "NOW IN GENE---------"

  g1 = Gene.new(64)
  g1[0] = 1
  g1[7] = 1
  g1.flip(5)
  g1.fitness = 35
  g1.print

  puts "NOW IN GENEPOOL---------"

  g1 = GenePool.new([2, 2, 4], [1], 2, false)
  g1.print

  puts "Setting 0, 1, 63, 127, 128, 191"
  g1.set(0, 1, 1)
  g1.set(0, 0, 1)
  g1.set(0, 63, 1)
  g1.set(0, 127, 1)
  g1.set(0, 128, 1)
  g1.set(0, 191, 1)
  g1.print
  puts "setMult "
  g1.setMult(0, 7, 2, 3)
  g1.setMult(0, 35, 8, 255)
  g1.setMult(1, 68, 8, 243)
  g1.print
  puts "Crossing"
  g1.cross(0, 1, 129)
  g1.print
  puts "Adding Gene 1"
  g1[1].fitness = 47
  g1.add(g1[1])
  g1.print
  puts "crossover"
  g1.setMult(2, 80, 8, 255)
  g1.crossover(g1[0], g1[2], 129)
  g1.print
  puts "mutating"
  g1.mutate(g1[0], 0.05)
  g1.print
  puts "size: #{g1.size}"
  g1.clear
  puts "now: #{g1.size}"
  g1.print

end

#test # - test the Gene class
