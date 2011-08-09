require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "User" do
   
  before :all do
    
    class User
      
      attr_accessor :key_specs,:keys
      def initialize (key_specs)
        @key_specs = key_specs
      end
      
      def keys (context)
        (@key_specs[context.to_sym]||[]).map{|a|a.split('.')}.uniq
      end
         
    end

    class Machine
      include Protected
      
      protect "money"
      def money_method
        true
      end
      
      protect "super"
      def admin_method
        true
      end
      
      protect "super","money"
      def money_admin_method
        true
      end
      
      unprotect
      def unprotected
        true
      end
      
    end
    
    @user    = User.new(:default => ["money"]) # Makes user with a 'money' key in the 'default' context
    @machine = Machine.new(@user, :default)  # Creates a machine in the default context for the above user
  end
    
  context "in the internal context" do  
  
    context "with a money key" do
   
      it "should be able to use the method locked by 'money'" do
        @machine.money_method.should be_true
      end
    
      it "should not be able to use the method locked by 'admin'" do
        expect { @machine.admin_method }.to raise_error(SecurityError)
      end
      
      it "should be able to access unprotected methods" do
        @machine.unprotected.should be_true
      end
    end
  
    context "with a 'super' key" do
      before do
        @user.key_specs= {:internal => ["super"]}
        @machine = Machine.new(@user, "internal")
      end
      it "should be able to access 'super' protected methods" do
        @machine.admin_method.should be_true
      end
      it "should not be able to access 'money' protected methods" do
        expect { @machine.money_method }.to raise_error(SecurityError)
      end
      it "should be able to access unprotected methods" do
        @machine.unprotected.should be_true
      end
    end
    
    context "with a 'super' and 'money' key" do
      before do
        @user.key_specs= {:internal => ["super","money"]}
        @machine = Machine.new(@user, "internal")
      end
      
      it "should be able to access 'super' protected methods" do
        @machine.admin_method.should be_true
      end      
      it "should be able to access 'money' protected methods" do
        @machine.money_method.should be_true
      end
      it "should be able to access the 'money' and 'super' protected methods" do
        @machine.money_admin_method.should be_true
      end
      it "should be able to access unprotected methods" do
        @machine.unprotected.should be_true
      end
    end    
  end
end
