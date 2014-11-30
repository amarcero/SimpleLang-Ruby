# Alan Marcero

############## M A I N ##############

class SimplelangController < ApplicationController

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


end # end class MainController



############## L E X E R ##############



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


# Sets up the scanner and manages the looping until all
# tokens have been extracted.
class Lexer < ApplicationController

  # enable reading/writing of file
  attr_accessor :file

  # constructor
  # create a new StringScanner obj with the input
  # post: assigns the StringScanner obj to @file
  def initialize(fStream)
    @file = StringScanner.new(fStream)
  end

  # gets the next token
  # pre:  the @file StringScanner has been constructed
  #     the build_token method is defined that accepts a
  #       type symbol and a data string
  # post: the next token has been passed to the build_token
  #       method which then returns the new token
  #     or nextToken returns an :EOF token on end of file
  def nextToken
    case

    # integer literals and float literals
    when @file.check(/\d/)
      # scan until the digits end
      region = @file.scan(/\d+/)

      # if the very next char is alpha, crash
      if @file.check(/[a-zA-Z]/)
        token_error "illegal token"

      # if the very next char is a .
      elsif @file.check(/\./)
        region << @file.getch # append the .
        decimal = @file.scan(/\d+/)
        # if there was at least 1 decimal after the "."
        # & no word chars directly after the digits
        if decimal && !@file.check(/\w+/)
          region << decimal
          build_token :FLOAT, region.to_f
        else
          token_error "bad floating-point literal"
        end
      else
        build_token :INT, region.to_i
      end


    # crashes on a floating point that starts with the point
    when @file.check(/\./)
      token_error "bad floating-point literal"



    # string literals
    when @file.check(/\"/)
      # get the "
      region = @file.getch

    # attempt to find the closing " or an end line
    scan = @file.scan_until(/$|\"/)

    # if the scan found a "
    if scan.last(1) == '"'
      region << scan # append scan to the opening "
      build_token :STRING, region

    else
      token_error "unclosed string literal"
    end


    # comments
    when @file.check(/\/\*/)
      keep_looking = true
      while keep_looking

        # if we've looked to the end of the file, crash
        if @file.eos?
          keep_looking = false
          token_error "unclosed comment"

          # scan for */ or end of line or EOF
        else
          region = @file.scan_until(/\*\/|\r\n|\z/)
          if region.last(2) == "*/"
            # we found the end of the comment
            keep_looking = false
          else
            @@lineCount += 1
          end
        end
      end
      nextToken

    # IDs
    when @file.check(/[a-zA-Z]/)
      region = @file.scan(/\w+/) # scan all word chars
      build_token :ID, region

    # plus +
    when @file.check(/\+/)
      @file.getch
      build_token :PLUS, " "

    # subtract -
    when @file.check(/\-/)
      @file.getch
      build_token :MINUS, " "

    # multiply *
    when @file.check(/\*/)
      @file.getch
      build_token :MULT, " "

    # divide /
    when @file.check(/\//)
      @file.getch
      build_token :DIVIDE, " "

    # modulus %
    when @file.check(/\%/)
      @file.getch
      build_token :MODULUS, " "

    # power ^
    when @file.check(/\^/)
      @file.getch
      build_token :POWER, " "

    # left paren (
    when @file.check(/\(/)
      @file.getch
      build_token :LPAREN, " "

    # right paren )
    when @file.check(/\)/)
      @file.getch
      build_token :RPAREN, " "

    # assignment =
    when @file.check(/\=/)
      @file.getch
      build_token :ASSIGN, " "

    # semicolon ;
    when @file.check(/\;/)
      @file.getch
      build_token :SEMICOLON, " "


    # newline
    when @file.check(/\r\n/)
      @@lineCount = @@lineCount + 1
      @file.scan_until(/\r\n/)
      nextToken

    # end of file
    when @file.check(/\z/)
      @file.scan_until(/\z/)
      build_token :EOF, " "

    # space or tab
    # this must be last since it will accept
    # on newline/eof
    when @file.check(/\s/)
      @file.getch
      nextToken

    # if all else fails...
    else
      token_error "invalid input"

    end # case
  end # def nextToken


  # creates a new Token
  # pre:  the input type is a symbol and data is a string
  # post: the newly constructed Token has been returned
  def build_token(type, data)
    Token.new(type, data, @@lineCount)
  end

  # calls crash with the input msg and the TOKEN error type
  # pre: crash must be defined in ApplicationController
  def token_error(msg)
    crash "TOKEN", msg + " at line " + @@lineCount.to_s
  end

end # class Lexer



############## P A R S E R ##############



# the class object used to construct a BinaryExpr tree
# pre:  when calling new, the left tree must be passed in
#       followed by the right tree, then the operator
# post: the newly constructed tree's data members
#       can be accessed through obj.left and obj.right
#       and the operator can be accessed by obj.op
class BinaryExpr < ApplicationController

  # so the left and right sub-trees, and the tree's
  # operator can be read
  attr_reader :left, :right, :op

  # when new is called on the class, this is called
  # it has the same pre/post conditions as the class
  def initialize(left, right, op)
    @left = left
    @right = right
    @op = op
  end

  # evaluates the tree using its lambda op
  # pre:  left and right must be of type BinaryExpr or Token
  #       there must be an evaluate method for Token
  #     if the BinaryExpr is an assignment, the left subtree
  #       must be the ID token, and the right subtree
  #       must be the value expression of that ID
  # post: returns the value of left op right
  #     or sets the left ID token to the value of right
  def evaluate
    # continues to call evaluate until it reaches the token
    # tokens must have an evaluate method that returns
    # the token's value
    begin
      self.op.call self.left, self.right

    rescue ZeroDivisionError
      crash "ZERO DIVISION", "can't divide by zero"
    rescue # all other errors
      # don't crash on errors
      # math with undefined variables will cause error
    end
  end
end


# parses a string of tokens
# pre:  the BinaryExpr and Lexer classes are defined
# post: returns an array of every AST
class Parser < ApplicationController

  # pre:  the parser is initialized
  # post: returns nil if the tokens have invalid syntax
  #       else it returns an array of all ASTs
  def parse
    toReturn = Array.new
    until @currTok.type == :EOF || @@errors
      toReturn.push(stmnt)
      if @currTok.type != :SEMICOLON
        parse_error "missing semicolon on line " +
        @lastTok.line.to_s
        # need to use @lastTok since @currTok is at
        # the next token
      else
        nextToken # go past the semicolon
      end
    end
    toReturn
  end

  private

  # pre: the string of tokens is passed in
  # post: the parser is ready to parse the tokens
  def initialize(code)
    @l = Lexer.new(code)
    nextToken
    # the token types that should have a value
    @evaluated_token_types = [:ID, :INT, :FLOAT]
  end

  # the method that should be called for each statement
  def stmnt
    originalToken = @currTok
    originalFile = @l.file.clone # copy StringScanner

    # check to see if the statement is an assignment
    if @currTok.type == :ID && nextToken.type == :ASSIGN
      nextToken # go past the assignment

      # build an assignment tree
      # left must be the ID token, right must be the
      # expr value
      BinaryExpr.new(originalToken, stmnt,
      lambda {|a,b| @@IDs.store(a.data, b.evaluate)})
    # else it's an expression
    else
      @currTok = originalToken # restore @currTok
      @l.file = originalFile # restore StringScanner
      expr
    end

  end



  # pre:  term and expr_p are defined
  # post: returns the result of expr_p as called with
  #       the result of term
  def expr
    expr_p(term)
  end

  # pre:  addop, nextToken, term, expr_p and the
  # BinaryExpr class must all be defined
  # post: if the currTok is not an addop, the passed in
  #       result is returned
  #     if the currTok is an addop, the nextToken
  #       is gotten and a BinaryExpr is constructed
  #       the result of expr_p is then returned
  #       as called with the BinaryExpr
  def expr_p(t)
    if op = addop # see if currTok is addop
      nextToken
      expr_p(BinaryExpr.new(t, term, op))
    else
      t
    end
  end


  # pre:  factor and term_p are defined
  # post: returns the result of term_p as called with
  #       the result of factor
  def term
    term_p(factor)
  end


  # pre:  multop, nextToken, factor, term_p, and the
  # BinaryExpr class must all be defined
  # post: if the currTok is not a multop, the passed in
  #       result is returned
  #     if the currTok is a multop, the nextToken
  #       is gotten and a BinaryExpr is constructed
  #       the result of term_p is then returned
  #     as called with the newly constructed BinaryExpr
  def term_p(t)
    if op = multop # see if currTok is multop
      nextToken
      term_p(BinaryExpr.new(t, factor, op))
    else
      t
    end
  end


  # returns the current token if @currTok is an INTLIT or ID
  # or calls expr if @currTok is an LPAREN
  # pre:  init must be called
  # post: the result of expr or the token has been returned
  def factor
    if @currTok.type == :MINUS
      nextToken # go past the minus
      BinaryExpr.new(nil, factor,
      lambda {|a, b| 0 - b.evaluate})

    elsif @evaluated_token_types.include?(@currTok.type)
      nextToken
      @lastTok # return the token

    elsif @currTok.type == :LPAREN
      temp = @currTok # remember where left paren started
      nextToken
      if t = stmnt
        if @currTok.type == :RPAREN
          nextToken
          t
        else
          parse_error "no closing paren beginning
          on line " + temp.line.to_s
        end
      end

    elsif @currTok.type == :SEMICOLON
      nextToken

    else
      parse_error "unexpected input on line " +
      @@lineCount.to_s
    end
  end


  # determines if @currTok is a +/-
  # pre:  @currTok must be the current token
  #     a plus token must be type :PLUS
  #     a minus token must be type :MINUS
  # post: returns an anonymous function to add
  #       or subtract two values
  def addop
    if @currTok.type == :PLUS
      lambda { |a,b| a.evaluate + b.evaluate }
    elsif @currTok.type == :MINUS
      lambda { |a,b| a.evaluate - b.evaluate }
    end
  end


  # determines if @currTok is a * or divide
  # pre:  @currTok must be the current token
  #     a multiply token must be type :MULT
  #     a divide token must be type :DIVIDE
  #     a modulus token must be type :MODULUS
  # post: returns an anonymous function to multiply
  #       or divide two values
  def multop
    if @currTok.type == :MULT
      lambda { |a,b| a.evaluate * b.evaluate }
    elsif @currTok.type == :DIVIDE
      lambda { |a,b| a.evaluate / b.evaluate }
    elsif @currTok.type == :MODULUS
      lambda { |a,b| a.evaluate % b.evaluate }
    elsif @currTok.type == :POWER
      lambda { |a,b| a.evaluate ** b.evaluate }
    end
  end

  # assigns @currTok to the next token from Lexer
  # pre:  the Lexer object must be accessible through @l
  # post: the Lexer object is at the next token
  def nextToken
    @lastTok = @currTok
    @currTok = @l.nextToken
  end

  # calls crash with the input msg and the PARSE error type
  # pre: crash must be defined in ApplicationController
  def parse_error(msg)
    crash "PARSE", msg
  end
end # class Parser
