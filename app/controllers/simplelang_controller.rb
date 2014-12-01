# Alan Marcero

class SimplelangController < ApplicationController

  # requires
  require 'binary_expr'
  require 'parser'
  require 'token'
  require 'lexer'

  # pre:  the data has been passed through "data"
  # post: the data has been evaluated
  def index
    @result = Array.new
    @input = ""
    if params[:data] != ""
      # get the input from Rails and parse it
      @ASTs=Parser.new(params[:data]).parse
      for tree in @ASTs
        value = tree.evaluate
        @result.push(value)
      end unless @@errors

      # return the input to the UI
      @input = params[:data].strip
    else
      crash "INPUT", "no input specified"
    end if request.post?

    # class variables are not accessible by the view
    @errors = @@errors
  end
end
