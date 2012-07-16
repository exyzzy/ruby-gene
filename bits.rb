# bits.rb: Class for minipulating bits in Ruby using Fixnums
# Note that usable bits on a Fixnum are: 0.size * 8 - 2   (integer marker and sign bit not usable)
# Author: Eric Lang
# For more info: www.exyzzy.com

class Bits
  attr_reader :size

  # size is number of bits in the bit string, it will be broken into words
  def initialize (size)
    @@wordBits = 0.size * 8               # size of a word on your machine
    @wordMax = 2**@@wordBits
    @xorMask = @wordMax - 1
    @bitMask = []                         # to speed things up precompute index masks
    @@wordBits.times { |i| @bitMask[i] = 1 << i }
    @size = size	    
    @words = (@size / @@wordBits) + [@size % @@wordBits, 1].min
    @bits = Array.new(@words, 0)
  end

  # set single bit at index
  def []=(index, value)
    if value == 1
      @bits[index/@@wordBits] |= @bitMask[index % @@wordBits]
    else
      @bits[index/@@wordBits] &= (@bitMask[index % @@wordBits] ^ @xorMask)
    end
  end

  # set multiple bits beginning at index (don't cross word boundary)
  def set(index, numBits, value)
    andMask = 2**numBits - 1                            # 000000001111
    andMask = andMask << (index % @@wordBits)           # 000011110000
    andMask = andMask ^ @xorMask                        # 111100001111
    @bits[index/@@wordBits] &= andMask                  # bbbb0000bbbb
    valMask = value << (index % @@wordBits)             # 0000vvvv0000
    @bits[index/@@wordBits] |= valMask                  # bbbbvvvvbbbb
  end

  # set a whole word
  def setWord(word, value)
    @bits[word] = value
  end

  # get single bit at index
  def [](index)
    @bits[index/@@wordBits] & @bitMask[index % @@wordBits] > 0 ? 1 : 0
  end

  # flip at bit at index
  def flip(index)
    value = @bits[index/@@wordBits] & @bitMask[index % @@wordBits] > 0 ? 1 : 0    
    if value == 0
      @bits[index/@@wordBits] |= @bitMask[index % @@wordBits]
    else
      @bits[index/@@wordBits] &= (@bitMask[index % @@wordBits] ^ @xorMask)
    end
  end

  # get multiple bits at index (don't cross word boundary)
  def get(index, numBits)
    andMask = 2**numBits - 1                            # 000000001111
    andMask = andMask << (index % @@wordBits)           # 000011110000
    value = @bits[index/@@wordBits] & andMask           # 0000vvvv0000
    value = value >> (index % @@wordBits)               # 00000000vvvv
    value
  end

  # get a whole word
  def getWord(word)
    @bits[word]
  end
  
  # print
  def print
    @bits.each_index do |i|
      puts "  %064d" % @bits[i].to_s(2)
    end
  end

  # duplicate a gene from another
  def duplicate(from)
    @bits.each_index {|i| @bits[i] = from.getWord(i)}
  end

  # iterate over all bits
  def each(&block)
    @size.times { |index| yield self[index]}
  end

  # iterate over all indices
  def each_index(&block)
    @size.times { |index| yield index}
  end

  # number of bits in a word on your machine (32 or 64)
  def wordBits
    @@wordBits
  end

  # largest integer in a word (not really, the top two bits revert to Bignum)
  def wordMax
    @wordMax
  end

  # number of words in your bit field
  def numWords
    @words
  end

end


def test
  myBits = Bits.new(100)
  myBits[0] = 1
  myBits[5] = 1
  myBits[7] = 1
  myBits.print
  if myBits[5] != 1 
    abort("FAIL: myBits[5] != 1")
  end
  if myBits.get(0, 8) != 161
    abort("FAIL: myBits.get(0, 8) != 161")
  end
  if myBits.get(5, 3) != 5
    abort("FAIL: myBits.get(5, 3) != 5")
  end
  myBits.flip(7)
  if myBits.get(5, 3) != 1
    abort("FAIL: myBits.get(5, 3) != 1")
  end
  if myBits.getWord(0) != 33
    abort("FAIL: myBits.getWord(0) != 33")
  end
  myBits.setWord(0, 4095)
  if myBits.getWord(0) != 4095
    abort("FAIL: myBits.getWord(0) != 4095")
  end
  newBits = Bits.new(100)
  newBits.duplicate(myBits)
  if newBits.getWord(0) != 4095
    abort("FAIL: newBits.getWord(0) != 4095")
  end
  puts "Bits: Success"
end

#test # - test Bits class
