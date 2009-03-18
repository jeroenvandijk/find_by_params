module ActiveRecord
	class Base
		def self.find_by_params(params = {}, options = {})
			scope = scoped_by_params(params, options)

			if params[:order_by]
				asc_or_desc = params[:order].to_i == 0 ? "ASC" : "DESC"   # i'm assuming here that ASC is default
				order = "`#{params[:order_by]}` #{asc_or_desc}"           # Note the ` quotes to prevent sql injection
			end

			options[:paginate] ? scope.paginate(:all, :page => params[:page], :per_page => options[:per_page], :order => order) : scope.find(:all, :order => order)
		end

		def self.count_by_params(params = {}, options = {})
			scoped_by_params(params).count
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
	end
end
