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
