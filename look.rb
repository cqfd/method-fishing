module Look
  def self.up(msg, obj)
    up_helper(msg, obj, obj.singleton_class)
  end

  def self.up_helper(msg, obj, ancestor)
    real_ancestors(ancestor).each do |a|
      instance_meths = a.instance_methods(false) + a.private_instance_methods(false)
      if instance_meths.include? msg
        unbound_meth = a.instance_method(msg)
        return unbound_meth.bind(obj)
      end
    end
    nil
  end

  def self.real_ancestors(a)
    if a.nil?
      []
    else
      if a.respond_to? :superclass
        rec_result = real_ancestors(a.superclass)
        new_modules = a.included_modules - rec_result
        [a] + new_modules + rec_result
      else
        [a] + a.included_modules
      end
    end
  end
end
