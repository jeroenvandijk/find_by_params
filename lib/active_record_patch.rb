module ActiveRecord
	class Base	
		class << self
			# Respond_to should also be extended because we have added methods dynamically
			def respond_to_with_associations?(method_id, include_private = false)
			  if match = ActiveRecord::DynamicScopeMatch.match(method_id)
			    return true if all_associations_exist?(match.attribute_names)
			  end

			  respond_to_without_associations?(method_id, include_private)
			end
	
			# TODO specify and refactor later on so that it can be added to rails
			def method_missing_with_associations(method_id, *arguments, &block)
				if match = ActiveRecord::DynamicScopeMatch.match(method_id)
			    field_names = match.attribute_names
					# raise method_id.inspect + self.inspect
					# TODO below is not beautiful, with the use of super we wouldn't need return
		      return method_missing_without_associations(method_id, arguments, &block) unless all_associations_exist?(field_names)
					
		      if match.scope?
						class_eval %{
		          def self.#{method_id}(*args)                                     # def self.scoped_by_region_id(*args)
		            options = args.extract_options!                                #   options = args.extract_options!
		            scope_hash = construct_scope_options_from_association_names(   #   scope_hash = construct_scope_options_from_association_names(
		              [:#{field_names.join(',:')}], args, options                  #     [:region_id, :function_id], args
		            )                                                              #   )
								scoped(scope_hash)                                             #   scoped(scope_hash)
		          end                                                              # end
		        }, __FILE__, __LINE__

		        send(method_id, *arguments)
		      end
				else
					method_missing_without_associations(method_id, arguments, &block)
				end
			end
			
			# It would be better to use inheritance, but scoped does not work right then. Since it is a hack to rails anyway we do it like thi
			alias_method_chain :respond_to?, :associations
			alias_method_chain :method_missing, :associations
	
			# TODO ideally this would be combined with the rails so that attributes and association can be mixed
			def all_associations_exist?(association_names)
				association_names.all? do |name| 
					found_reflection = find_reflection( extract_association(name) )
					found_reflection && !(name.to_s.include?("_id") && (found_reflection.macro == :belong_to) ) # TODO very hacky, make it work together with rails scoped_by
				end
			end

			def extract_association(method_id)
				method_id.to_s.gsub("_id", '')
			end

			def find_reflection(association_name)
				reflections[association_name.to_sym] || reflections[association_name.to_s.pluralize.to_sym]  # we only need to change it to plural in case of id of a plural relation e.g. status_id where the model has_many :statuses
			end
			
			def find_includes(association, use_join_table = true)
				reflection = find_reflection(association)
				
				includes = []
				includes << reflection.options[:through]
				includes << reflection.name unless use_join_table
				
				includes.compact
			end

			def all_fields_exist?(field_names)
				attribute_names = expand_attribute_names_for_aggregates(attribute_names)
				attribute_names.all? { |name| column_methods_hash.include?(name.to_sym) || find_reflection(name.to_sym) }
      end
				
			def association_exist?(field_name)
				!!find_reflection(field_name)
			end

			# create scope hash given association names and arguments the argument can be an number in case of an id or
			# it is a hash in which the key points to the field of the association table and the value points to the value
			# where we are looking for.
			# E.g.
			# scoped_by_user_id(6) creates the query :conditions => ["object_user_members.user_id IN (?)", 6], :include => [:users]
			# scoped_by_user(:name => "jeroen") creates the query :conditions => ["users.name IN (?)", "jeroen"], :include => [:users]
			# scoped_by_user(:like_name => "jeroen") creates the query :conditions => ["users.name LIKE ?", "%jeroen%"], :include => [:users]
			def construct_scope_options_from_association_names(association_names, arguments, options = {})
				includes = []
				prepared_conditions = []
				prepared_arguments = []
				association_names.each_with_index do |name, idx|
					name = name.to_s
					
					association_name = extract_association(name)
					reflection = find_reflection(association_name)
					
					use_join_table = name.include?("_id")
					# table name is either the name of the join table or the name of the table self # NOT sure why self.name is necessary
					table_name = (use_join_table ? (reflection.options[:join_table] || reflection.options[:through] || self.name ) : association_name.pluralize ).to_s.tableize
					
					# the field name is either the given name (when a name followed by _id is given, or it is a hash)
					field_name, prepared_arguments[idx] = (use_join_table ? [name, arguments[idx] ] : options.to_a.flatten[idx*2..idx*2+1] )

					field_name = field_name.to_s # we want it to be a string

					# Handle the situation where the name has like_ prefix meaning we need to introduce wildcards
					if field_name.include?("like_")
						field_name = field_name.gsub("like_", '')                              # remove the like_ prefix
						prepared_arguments[idx] = "%" + prepared_arguments[idx] + "%"          # add wildcards
						use_like = true
					end
					
					prepared_conditions << (use_like ? ["`#{table_name}`.`#{field_name}` LIKE ?"] : ["`#{table_name}`.`#{field_name}` IN (?)"] )
					
					includes += find_includes( association_name, use_join_table)
				end

				{:conditions => [prepared_conditions.join(" AND "), *prepared_arguments], :include => includes.uniq}
			end

		end
	end
	
end