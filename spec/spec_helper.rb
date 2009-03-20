$: << File.dirname(__FILE__) + '/../lib'
# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require 'rubygems'
%w[spec rails/version active_record].each &method(:require)
#%w[spec rails/version action_pack active_record
#   action_controller action_controller/test_process action_controller/integration].each &method(:require)

require 'find_by_params'
# require 'rails_generator/scripts/generate'
# require 'rails_generator/scripts/destroy'
# require 'active_support'

# %w[spec dm]+.each &method(:require)

Spec::Runner.configure do |config|
  config.mock_with :mocha
end