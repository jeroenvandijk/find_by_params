require File.dirname(__FILE__) + '/spec_helper'

describe "Added class methods to ActiveRecord::Base" do
  before :each do
    @params  = { :foo => 1, :bar => 2 }
    @options = { :foo => 3, :bar => 4 }
    
    @base = ActiveRecord::Base
    @scope = mock("scope") 
  end
  
  describe "find_by_params" do
    it "should pass all the params and options to #scope_by_params" do
      @scope.stubs(:find => 1)
      @base.expects(:scoped_by_params).with(@params, @options).returns(@scope)
      @base.find_by_params(@params, @options)
    end
    
    describe "ordering" do
      before :each do
        @base.expects(:scoped_by_params).with(@params, @options).returns(@scope)
      end

      it "should add ordering when order and order by is added" do
        params = @params.merge(:order => 1, :order_by => "field_name")
        @scope.expects(:find).with(:all, :order => "`field_name` DESC")
        @base.find_by_params(params, @options)
      end

      it "should default to DESC" do
        params = @params.merge(:order_by => "field_name")
        @scope.expects(:find).with(:all, :order => "`field_name` ASC")
        @base.find_by_params(params, @options)        
      end
      
      it "should be DESC when params[:order] equals 1" do
        params = @params.merge(:order => 1, :order_by => "field_name")
        @scope.expects(:find).with(:all, :order => "`field_name` DESC")
        @base.find_by_params(params, @options)        
      end
    end
    
    it "should call paginate with params[:per_page] when params[:paginate] is true" do
      params = @params.merge(:page => 1)
      options = @options.merge(:per_page => 3, :paginate => true) 
      @base.expects(:scoped_by_params).with(@params, @options).returns(@scope)
      @scope.expects(:paginate).with(:all, :page => 1, :per_page => 3, :order => nil)
      @base.find_by_params(params, options)
    end

    it "should call find when params[:paginate] is blank" do
      @base.expects(:scoped_by_params).with(@params, @options).returns(@scope)
      @scope.expects(:find)
      @base.find_by_params(@params, @options)
    end
  end

  describe "count_by_params" do
    it "should pass all the params and options to #scope_by_params" do
      @scope.stubs(:count => 1)
      @base.expects(:scoped_by_params).with(@params, @options).returns(@scope)
      @base.count_by_params(@params, @options)
    end
    
    it "should call count on #scope_by_params" do
      @scope.expects(:count)
      @base.stubs(:scoped_by_params).returns(@scope)
      @base.count_by_params
    end
  end

  describe "scoped_by_params" do
    before :each do
      @base.stubs(:scoped).returns(@scope)
    end
    
    it "should not call #scoped_by_user_id when params[:user_id] is blank?" do
      params = {:user_id => nil, :user_id => "" }
      @scope.expects(:scoped_by_user_id).never
      @base.scoped_by_params(params)
    end
    
    describe "with no-blank params" do
      it "should not call #scoped_by_user_id when a model does not respond to #scoped_by_user_id" do
        params = {:user_id => 1}
        @scope.expects(:scoped_by_user_id).never
        @base.stubs(:respond_to?).with { |v| v == :scoped_by_user_id || v == "scoped_by_user_id" }.returns(false)
        @base.scoped_by_params(params)
      end
    
      it "should call #scoped_by_user_id with params[:user_id] when a model responds to #scoped_by_user_id" do
        params = {:user_id => 1}
        @scope.expects(:scoped_by_user_id).with(1).once
        @base.stubs(:respond_to?).with { |v| v == :scoped_by_user_id || v == "scoped_by_user_id" }.returns(true)
        @base.scoped_by_params(params)
      end
    end
  end
end