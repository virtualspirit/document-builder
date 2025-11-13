module Document
  module ShrinePlugins
    module EmbeddedMongoidSupport
      module AttacherClassMethods
        def load_record(data)
          if data["parent"]
            parent_class, parent_id, association_name = data["parent"]
            child_class, child_id = data["record"]
    
            parent_class = Object.const_get(parent_class)
            parent       = find_record(parent_class, parent_id)
            association  = parent.send(association_name)
    
            association.where(id: child_id).first
          else
            super
          end
        end
      end
    
      module AttacherMethods
        def dump
          hash = super
          if record.embedded?
            hash["parent"] = [
              record._parent.class.to_s,
              record._parent.id.to_s,
              record.association_name.to_s
            ]
          end
          hash
        end
    
        def swap(new_file)
          if record.embedded?
            association = record._parent.send(record.association_name)
            reloaded = association.where(id: record.id).first
            return if reloaded.nil? || self.class.new(reloaded, name).read != read
            update(new_file)
          else
            super
          end
        end
      end
    end
  end
end