 # Alan Marcero

 class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  # variables that will be accessible to all classes
  # that inherit ApplicationController
  def initialize
    @@errors = nil
    @@lineCount = 1
    @@IDs = Hash.new
  end

  # pre:  @@errors must be nil - only 1 error will be pushed
  # post: the input error & msg are in the @@errors variable
  #       returns a Hash with :type as the error type
  #         and :msg as the error message
  def crash(error, msg)
    unless @@errors
      @@errors = Hash[:type => error + " ERROR", :msg => msg]
      nil # return nil to the system
    end
  end
end
