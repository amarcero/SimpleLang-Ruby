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
