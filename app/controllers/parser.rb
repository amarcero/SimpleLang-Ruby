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
