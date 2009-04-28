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
    
    it "should pass all the params and options to #order_by_params" do
      @scope.stubs(:find => 1)
      @base.expects(:scoped_by_params).returns(@scope)
      @base.expects(:order_by_params).with(@params, @options)
      @base.find_by_params(@params, @options)
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

  describe "order_by_params" do
    before :each do
    end
  
    it "should add ordering with direction ASC when order_by is in params" do
      @base.order_by_params(:order_by => "field.name").should == "`field`.`name` ASC"
    end
    
    it "should return nil when :order_by or :orderings is not given" do
      @base.order_by_params({:direction => 1}).should == nil
    end
    
    describe "should add ordering with direction DESC when" do
      it "is given :direction => :desc" do
        @base.order_by_params(:order_by => "name", :direction => :desc).should == "`name` DESC"
      end
      
      it "is given :direction => 1" do
        @base.order_by_params(:order_by => "name", :direction => 1).should == "`name` DESC"
      end
    end
    
    it "should add multiple orderings when :ordering is given" do
      @base.order_by_params(:ordering => [ { :order_by => "name", :direction => :desc }, { :order_by => "age" } ] ).should == "`name` DESC, `age` ASC"
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
		describe "should prevents sql injection by" do
			class Dummy < ActiveRecord::Base
				belongs_to :user
			end

			it "removing evil characters from first level fields" do
				params = { "u'ser`_id" => 1 }
				pending "not sure how to test this on AR::Base => integration tests needed" do
					@base.scoped_by_params(params).proxy_options.should == {:conditions=> ["user_id = ?", 1] }
				end
			end
		
			it "removing evil characters from first level fields" do
				params = { "user" => { "na`'me" => "jeroen"} }
				pending "not sure how to test this on AR::Base => integration tests needed" do
					@base.scoped_by_params(params).proxy_options.should == {:conditions=> ["users.name = ?", "jeroen"], :include=>[:users]}
				end
			end

		end


    it "should not call #scoped_by_user_id when params[:user_id] is blank?" do
      params = {:user_id => nil, :user_id => "" }
      @scope.expects(:scoped_by_user_id).never
      @base.scoped_by_params(params)
    end
    
    it "should not call #scoped_by_city_region_id when params[:city][:region_id] is blank?" do
      params = { :city => { :region_id => nil}, :city => { :region_id => "" } }
      @scope.expects(:scoped_by_city).never
      @base.scoped_by_params(params)
    end
    
    it "should add a limit scope when options[:limit] is given" do
      @base.scoped_by_params({}, :limit => 1).proxy_options.should == { :limit => 1 }
    end
    
    describe "with no-blank params" do
      before(:each) do
        @base.stubs(:scoped).returns(@scope)
      end

      it "should call #scoped_by_user_id when params[:user_id] is false" do
        params = {:user_id => false}
        @base.stubs(:respond_to?).returns(true)
        @scope.expects(:scoped_by_user_id).with(false).once        
        @base.scoped_by_params(params)
      end

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