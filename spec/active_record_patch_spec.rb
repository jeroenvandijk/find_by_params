require File.dirname(__FILE__) + '/spec_helper'

describe "active record patch" do
  before :each do
    @base = ActiveRecord::Base
  end
  
  describe "attributes" do
    describe "attribute 'foo_id' exist" do
      before :each do
        @base.stubs(:column_methods_hash => [:foo_id])
      end

      it "should respond to #scoped_by_foo_id" do
        @base.respond_to?(:scoped_by_foo_id).should be true
      end

      it "should return a scope with correct conditions when #scoped_by_foo_id gets called" do
        scope = @base.scoped_by_foo_id(1)
        scope.proxy_options.should == {:conditions => {:foo_id => 1} }
      end
    end
    
    describe "attribute 'bar_id' does exist" do
      before :each do
        @base.stubs(:column_methods_hash => [])
      end

      it "should not respond to #scoped_by_bar_id" do
        @base.respond_to?(:scoped_by_bar_id).should be false
      end
    
      it "should raise a #MethodMissingException when #scoped_by_bar_id gets called" do
        lambda{ @base.scoped_by_bar_id(1) }.should raise_error("undefined method `scoped_by_bar_id' for ActiveRecord::Base:Class")
      end
    end  
  end
  
  describe "associations" do
    describe "=> singular, monkey exist" do
      before :each do
        @base.stubs(:column_methods_hash => [:monkey_id])
        monkey_reflection = @base.create_reflection(:belongs_to, :monkey, {}, @base)
        # @base.stubs(:reflections => {:monkey => monkey_reflection})
      end
      
      it "should respond to #scoped_by_monkey" do
        # raise @base.reflections.inspect
        # @base.respond_to?(:scoped_by_monkey).should be true
      end
      it "should return a scope with correct conditions when #scoped_by_monkey gets called"
    end
    
    describe "=> singular, duck does not exist" do
      it "should not respond to #scoped_by_duck"
      it "should raise a #MethodMissingException when #scoped_by_duck gets called"
    end
  end


end