module Protected

  module ClassMethods
    
    # Protects methods defined afterward so that they may only be called on
    # instances with a key which matches the specified lock. Multiple locks
    # may be specified, in which case _all_ locks must be opened for the
    # action to be permitted.
    # 
    #   protect "admin "           ->  The admin key is required.
    #   protect "admin", "money"   ->  Both the admin _and_ money key is required.
    # 
    def protect (*locks)
      @protected_locks = locks.map{|l|l.split('.')}
    end
    
    # Stops protecting methods defined after this point.
    def unprotect ()
      @protected_locks = nil
    end
    
    # Returns a hash of information about protected methods.
    def protected_methods
      @protected_methods ||= {}
    end
    
    private
    
    # Called when a method is added. Adds the method to the
    # protected_methods hash.
    def method_added (name)
      protected_methods[name] = @protected_locks if @protected_locks
    end
    
  end

  module InstanceMethods
    
    # Sets up protection by overriding methods that aren't allowed.
    def initialize (user, contexts, *args, &block)
      keys = user.keys(*contexts)
      # For each method which has protection.
      self.class.protected_methods.each { |name, locks|
        # Only use those keys whose tags all appear somewhere in the locks.
        usable_keys = keys.select{|key| key & locks.flatten == key}
        # Are there any locks which none of the usable keys open?
        if locks.any? { |lock| (lock & usable_keys.flatten).empty? }
          # If there's a lock, override the protected method with one that
          # raises a security error.
          singleton_class.send(:define_method, name) do
            raise SecurityError, "#{self.class.name}##{name} is protected: tags required: #{locks.map{|l|l.join(".")}.join(', and ')}"
          end
          puts "Locking down #{self.class.name}##{name}"
        else
          puts "Not locking down #{self.class.name}##{name}"
        end
      }
      super(*args, &block)
    end
    
  end
  
  def self.included (other)
    other.send(:extend, ClassMethods)
    other.send(:include, InstanceMethods)
  end
  
end

