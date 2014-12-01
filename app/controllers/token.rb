# pre: the type has been passed as the token type
# the data has been passed as the data of the token
class Token < ApplicationController

  # enable reading of type/data/line
  attr_reader :type, :data, :line

  # constructs a new token
  # pre:  the input type is the type of the token
  #     the input data is the token data
  #     line is the line the token occurs on
  # post: a new token has been constructed
  def initialize(type, data, line)
    @type = type
    @data = data
    @line = line
  end

  # returns the value of the token
  def evaluate
    value = nil
    if self.type == :ID
      if !value = @@IDs[self.data]
        crash "RUNTIME", self.data +
        " not initialized at line " +
        self.line.to_s
      end
    else
      value = self.data
    end
    value
  end

end
