require_relative 'spec_helper'
require_relative '../../shared/hash/key_error'

load_extension("hash")

describe "C-API Hash function" do
  before :each do
    @s = CApiHashSpecs.new
  end

  describe "rb_hash" do
    it "calls #hash on the object" do
      obj = mock("rb_hash")
      obj.should_receive(:hash).and_return(5)
      @s.rb_hash(obj).should == 5
    end

    it "converts a Bignum returned by #hash to a Fixnum" do
      obj = mock("rb_hash bignum")
      obj.should_receive(:hash).and_return(bignum_value)

      # The actual conversion is an implementation detail.
      # We only care that ultimately we get a Fixnum instance.
      @s.rb_hash(obj).should.between?(fixnum_min, fixnum_max)
    end

    it "calls #to_int to converts a value returned by #hash to a Fixnum" do
      obj = mock("rb_hash to_int")
      obj.should_receive(:hash).and_return(obj)
      obj.should_receive(:to_int).and_return(12)

      @s.rb_hash(obj).should == 12
    end

    it "raises a TypeError if the object does not implement #to_int" do
      obj = mock("rb_hash no to_int")
      obj.should_receive(:hash).and_return(nil)

      -> { @s.rb_hash(obj) }.should raise_error(TypeError)
    end
  end

  describe "rb_hash_new" do
    it "returns a new hash" do
      @s.rb_hash_new.should == {}
    end

    it "creates a hash with no default proc" do
      @s.rb_hash_new {}.default_proc.should be_nil
    end
  end

  describe "rb_hash_new_capa" do
    it "returns a new hash" do
      @s.rb_hash_new_capa(3).should == {}
    end

    it "creates a hash with no default proc" do
      @s.rb_hash_new_capa(3) {}.default_proc.should be_nil
    end

    it "raises RuntimeError when negative index is provided" do
      -> { @s.rb_hash_new_capa(-1) }.should raise_error(RuntimeError, "st_table too big")
    end
  end

  describe "rb_ident_hash_new" do
    it "returns a new compare by identity hash" do
      result = @s.rb_ident_hash_new
      result.should == {}
      result.compare_by_identity?.should == true
    end
  end

  describe "rb_hash_dup" do
    it "returns a copy of the hash" do
      hsh = {}
      dup = @s.rb_hash_dup(hsh)
      dup.should == hsh
      dup.should_not equal(hsh)
    end
  end

  describe "rb_hash_freeze" do
    it "freezes the hash" do
      @s.rb_hash_freeze({}).frozen?.should be_true
    end
  end

  describe "rb_hash_aref" do
    it "returns the value associated with the key" do
      hsh = {chunky: 'bacon'}
      @s.rb_hash_aref(hsh, :chunky).should == 'bacon'
    end

    it "returns the default value if it exists" do
      hsh = Hash.new(0)
      @s.rb_hash_aref(hsh, :chunky).should == 0
      @s.rb_hash_aref_nil(hsh, :chunky).should be_false
    end

    it "returns nil if the key does not exist" do
      hsh = { }
      @s.rb_hash_aref(hsh, :chunky).should be_nil
      @s.rb_hash_aref_nil(hsh, :chunky).should be_true
    end
  end

  describe "rb_hash_aset" do
    it "adds the key/value pair and returns the value" do
      hsh = {}
      @s.rb_hash_aset(hsh, :chunky, 'bacon').should == 'bacon'
      hsh.should == {chunky: 'bacon'}
    end
  end

  describe "rb_hash_clear" do
    it "returns self that cleared keys and values" do
      hsh = { :key => 'value' }
      @s.rb_hash_clear(hsh).should equal(hsh)
      hsh.should == {}
    end
  end

  describe "rb_hash_delete" do
    it "removes the key and returns the value" do
      hsh = {chunky: 'bacon'}
      @s.rb_hash_delete(hsh, :chunky).should == 'bacon'
      hsh.should == {}
    end
  end

  describe "rb_hash_delete_if" do
    it "removes an entry if the block returns true" do
      h = { a: 1, b: 2, c: 3 }
      @s.rb_hash_delete_if(h) { |k, v| v == 2 }
      h.should == { a: 1, c: 3 }
    end

    it "returns an Enumerator when no block is passed" do
      @s.rb_hash_delete_if({a: 1}).should be_an_instance_of(Enumerator)
    end
  end

  describe "rb_hash_fetch" do
    before :each do
      @hsh = {:a => 1, :b => 2}
    end

    it "returns the value associated with the key" do
      @s.rb_hash_fetch(@hsh, :b).should == 2
    end

    it "raises a KeyError if the key is not found and default is set" do
      @hsh.default = :d
      -> { @s.rb_hash_fetch(@hsh, :c) }.should raise_error(KeyError)
    end

    it "raises a KeyError if the key is not found and no default is set" do
      -> { @s.rb_hash_fetch(@hsh, :c) }.should raise_error(KeyError)
    end

    context "when key is not found" do
      it_behaves_like :key_error, -> obj, key {
        @s.rb_hash_fetch(obj, key)
      }, { a: 1 }
    end
  end

  describe "rb_hash_foreach" do
    it "iterates over the hash" do
      hsh = {name: "Evan", sign: :libra}

      out = @s.rb_hash_foreach(hsh)
      out.equal?(hsh).should == false
      out.should == hsh
    end

    it "stops via the callback" do
      hsh = {name: "Evan", sign: :libra}

      out = @s.rb_hash_foreach_stop(hsh)
      out.size.should == 1
    end

    it "deletes via the callback" do
      hsh = {name: "Evan", sign: :libra}

      out = @s.rb_hash_foreach_delete(hsh)
      out.should == {name: "Evan", sign: :libra}
      hsh.should == {}
    end
  end

  describe "rb_hash_bulk_insert" do
    it 'inserts key-value pairs into the hash' do
      arr = [:a, 1, :b, 2, :c, 3]
      hash = {}

      @s.rb_hash_bulk_insert(arr.length, arr, hash)

      hash.should == {a: 1, b: 2, c: 3}
    end

    it 'overwrites existing keys' do
      arr = [:a, 4, :b, 5, :c, 6]
      hash = {a: 1, b: 2}

      @s.rb_hash_bulk_insert(arr.length, arr, hash)

      hash.should == {a: 4, b: 5, c: 6}
    end

    it 'uses the last key in the array if it appears multiple times' do
      arr = [:a, 1, :b, 2, :a, 3]
      hash = {}

      @s.rb_hash_bulk_insert(arr.length, arr, hash)

      hash.should == {a: 3, b: 2}
    end

    it 'allows the array to be NULL if the length is zero' do
      hash = {}

      @s.rb_hash_bulk_insert(0, nil, hash)

      hash.should == {}
    end

    it 'does not include any keys after the given length' do
      arr = [:a, 1, :b, 2, :c, 3, :d, 4]
      hash = {}

      @s.rb_hash_bulk_insert(arr.length - 2, arr, hash)

      hash.should == {a: 1, b: 2, c: 3}
    end

    it 'does not modify the hash if the length is zero' do
      arr = []
      hash = {a: 1, b: 2}

      @s.rb_hash_bulk_insert(arr.length, arr, hash)

      hash.should == {a: 1, b: 2}
    end
  end

  describe "rb_hash_size" do
    it "returns the size of the hash" do
      hsh = {fast: 'car', good: 'music'}
      @s.rb_hash_size(hsh).should == 2
    end

    it "returns zero for an empty hash" do
      @s.rb_hash_size({}).should == 0
    end
  end

  describe "rb_hash_lookup" do
    it "returns the value associated with the key" do
      hsh = {chunky: 'bacon'}
      @s.rb_hash_lookup(hsh, :chunky).should == 'bacon'
    end

    it "does not return the default value if it exists" do
      hsh = Hash.new(0)
      @s.rb_hash_lookup(hsh, :chunky).should be_nil
      @s.rb_hash_lookup_nil(hsh, :chunky).should be_true
    end

    it "returns nil if the key does not exist" do
      hsh = { }
      @s.rb_hash_lookup(hsh, :chunky).should be_nil
      @s.rb_hash_lookup_nil(hsh, :chunky).should be_true
    end

    describe "rb_hash_lookup2" do
      it "returns the value associated with the key" do
        hash = {chunky: 'bacon'}

        @s.rb_hash_lookup2(hash, :chunky, nil).should == 'bacon'
      end

      it "returns the default value if the key does not exist" do
        hash = {}

        @s.rb_hash_lookup2(hash, :chunky, 10).should == 10
      end

      it "returns undefined if that is the default value specified" do
        hsh = Hash.new(0)
        @s.rb_hash_lookup2_default_undef(hsh, :chunky).should be_true
      end
    end
  end

  describe "rb_hash_set_ifnone" do
    it "sets the default value of non existing keys" do
      hash = {}

      @s.rb_hash_set_ifnone(hash, 10)

      hash[:chunky].should == 10
    end
  end

  describe "rb_Hash" do
    it "returns an empty hash when the argument is nil" do
      @s.rb_Hash(nil).should == {}
    end

    it "returns an empty hash when the argument is []" do
      @s.rb_Hash([]).should == {}
    end

    it "tries to convert the passed argument to a hash by calling #to_hash" do
      h = BasicObject.new
      def h.to_hash; {"bar" => "foo"}; end
      @s.rb_Hash(h).should == {"bar" => "foo"}
    end

    it "raises a TypeError if the argument does not respond to #to_hash" do
      -> { @s.rb_Hash(42) }.should raise_error(TypeError)
    end

    it "raises a TypeError if #to_hash does not return a hash" do
      h = BasicObject.new
      def h.to_hash; 42; end
      -> { @s.rb_Hash(h) }.should raise_error(TypeError)
    end
  end

  describe "hash code functions" do
    it "computes a deterministic number" do
      hash_code = @s.compute_a_hash_code(53)
      hash_code.should be_an_instance_of(Integer)
      hash_code.should == @s.compute_a_hash_code(53)
      @s.compute_a_hash_code(90).should == @s.compute_a_hash_code(90)
    end
  end
end
