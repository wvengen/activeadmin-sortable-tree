module ActiveAdmin::Sortable
  module ControllerActions

    attr_accessor :sortable_options

    def sortable(options = {})
      options.reverse_merge! :sorting_attribute => options[:nested_set] ? :lft : :position,
                             :parent_method => :parent,
                             :children_method => :children,
                             :roots_method => :roots,
                             :tree => false,
                             :max_levels => 0,
                             :protect_root => false,
                             :collapsible => false, #hides +/- buttons
                             :start_collapsed => false

      if options[:nested_set] and not options[:roots_method]
        options[:roots_collection] ||= proc { where(options[:parent_method] => nil) }
      end

      # BAD BAD BAD FIXME: don't pollute original class
      @sortable_options = options

      # disable pagination
      config.paginate = false

      collection_action :sort, :method => :post do
        resource_name = active_admin_config.resource_name.to_s.underscore.parameterize('_')

        records = params[resource_name].inject({}) do |res, (resource, parent_resource)|
          res[resource_class.find(resource)] = resource_class.find(parent_resource) rescue nil
          res
        end
        errors = []
        ActiveRecord::Base.transaction do

          if options[:nested_set]
            # TODO perhaps don't rely on awesome_nested_set's move_to_* methods
            records.each do |(record, parent_record)|
              if not parent_record
                record.move_to_root
              elsif parent_record.children.empty?
                record.move_to_child_of parent_record
              elsif (lastchild = parent_record.children.last) != record
                record.move_to_right_of lastchild
              end
            end
            records.each do |(record, parent_record)|
              errors << {record.id => record.errors} if !record.save
            end

          else
            records.each_with_index do |(record, parent_record), position|
              record.send "#{options[:sorting_attribute]}=", position
              if options[:tree]
                record.send "#{options[:parent_method]}=", parent_record
              end
              errors << {record.id => record.errors} if !record.save
            end

          end
        end
        if errors.empty?
          head 200
        else
          render json: errors, status: 422
        end
      end

    end

  end

  ::ActiveAdmin::ResourceDSL.send(:include, ControllerActions)
end
