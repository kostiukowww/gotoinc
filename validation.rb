# frozen_string_literal: true

# Validation module (include to class to use validations)
module Validation
  def self.included(base)
    base.extend(ClassMethods)
    base.class_variable_set(:@@validations, [])
  end

  # Class Methods submodule will extended to class on Validation module include
  module ClassMethods
    # Adding new validation to @@validations collection
    def validate(attr_name, condition)
      class_variable_get(:@@validations) << { attr_name: attr_name, condition: condition }
    end
  end

  # Iterating each validation added by "validate" class method, check it and raise error if validation failed
  def validate!
    validations.each do |v|
      value = send v[:attr_name]
      unless validate_value(value, v[:condition])
        raise ArgumentError, "#{v[:attr_name]} validation failed, #{v[:condition]} missmatch"
      end
    end
  end

  # same like validate, but return false if any validate mismatch
  def valid?
    validations.each do |v|
      value = send v[:attr_name]
      return false unless validate_value(value, v[:condition])
    end
    true
  end

  private

  # Go thouth each validation condition in the list, return false if it was failed
  def validate_value(value, conditions)
    conditions.each do |validation_type, validation_condition|
      case validation_type
      when :presence
        return false if value.nil? || value.empty?
      when :format
        return false unless validation_condition.match?(value)
      when :type
        return false unless value.class == validation_condition
      else
        raise 'VALIDATION TYPE INVALID'
      end
    end
    true
  end

  def validations
    # tinny method to get class variable from included method
    self.class.class_variable_get(:@@validations)
  end
end

class User
  include Validation

  attr_accessor :name
  attr_accessor :number
  attr_accessor :owner

  validate :name, presence: true
  validate :number, format: /A-Z{0,3}/, presence: true
  validate :owner, type: Integer
end

# Valid case:
user = User.new
user.name = 'aaa'
user.number = 'A-ZZZ'
user.owner = 1
p user.valid?
user.validate!
# => true

# Invalid case:
user = User.new
user.name = 'A-ZZZ'
user.number = 'B'
user.owner = 1
p user.valid?
user.validate!

# false
# Traceback (most recent call last):
#         3: from 1.rb:87:in `<main>'
#         2: from 1.rb:20:in `validate!'
#         1: from 1.rb:20:in `each'
# 1.rb:23:in `block in validate!': number validation failed, {:format=>/A-Z{0,3}/, :presence=>true} missmatch (ArgumentError)
