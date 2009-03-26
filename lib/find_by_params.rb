module ActiveRecord
	class Base
		def self.find_by_params(params = {}, options = {})
			params_not_for_scoping = [:page, :order_by, :order]
			options_not_for_scoping = [:per_page, :paginate]
			
			scope = scoped_by_params(params.reject  {|k, v| params_not_for_scoping.include?(k.to_sym) },
															 options.reject {|k, v| options_not_for_scoping.include?(k.to_sym) })

			# create the order part of the query, supports multiple order columns and directions
			order = create_order(params[:ordering] ? params[:ordering] : [params]) if params[:ordering] || params[:order_by]

			options[:paginate] ? scope.paginate(:all, :page => params[:page], :per_page => options[:per_page], :order => order) : scope.find(:all, :order => order)
		end

		def self.count_by_params(params = {}, options = {})
			scoped_by_params(params, options).count
		end


		# Searches for scoped_by_* methods to call. Scoped_by_* methods are dynamically generated
		# and can normally handle one argument. With the AR patch we can give it also a hash so that it
		# looks for fields on other models.
		def self.scoped_by_params(params = {}, options = {})
			scope = self.scoped({})

			params.each_pair do |param_key, param_value|
				if !param_value.blank?
					field_name = param_key

					if param_value.is_a?(Hash)                                                # say customer[name] = "jeroen"
						arguments = Hash[*param_value.to_a.first]                               # only use the first key-value pair
					else
						arguments = param_value
					end

					method_id = "scoped_by_#{field_name}"

					scope = scope.send(method_id, arguments ) if self.respond_to?(method_id)
				end
			end

			scope
		end
		
		# expects an array of params hashes, where each ordering hash
		# includes at least an :order_by and optionally an :order value
		def self.create_order(orders)
			orders.map do |params|
				if ["DESC", "ASC"].include?(params[:order].to_s.upcase)
					asc_or_desc = params[:order].to_s.upcase
				else
					asc_or_desc = params[:order].to_i == 0 ? "ASC" : "DESC" # i'm assuming here that ASC is default
				end

				"`#{params[:order_by].gsub('.', '`.`')}` #{asc_or_desc}"
			end.join(", ")
		end
		
		
	end
end
