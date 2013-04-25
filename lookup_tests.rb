require 'minitest/autorun'
require_relative 'look'

class TestSimpleStuff < MiniTest::Unit::TestCase
  class Food
    def initialize(kind, calories)
      @kind = kind
      @calories = calories
    end
    def say_hi
      "Hi! I'm a #{@kind} and I'm going to cost you #{@calories} calories."
    end
  end

  def test_looking_up_regular_instance_methods_works
    bagel = Food.new("bagel", 100)
    assert_equal(bagel.say_hi,
                 Look.up(:say_hi, bagel).call)
  end

  def test_lookup_fails_on_nonexistent_methods
    french_fry = Food.new("french fry", 20)
    assert_raises(NoMethodError) { french_fry.derp }
    assert_nil(Look.up(:derp, french_fry))
  end

  def test_trying_to_access_instance_variables_wont_work
    pizza = Food.new("pizza", 1000)
    assert_raises(NoMethodError) { pizza.kind }
    assert_raises(NoMethodError) { pizza.calories }
    assert_nil(Look.up(:kind, pizza))
    assert_nil(Look.up(:calories, pizza))
  end
end

class TestIncludingModules < MiniTest::Unit::TestCase
  module M
    def say_hi
     "Hi!" 
    end
  end

  class Foo
    include(M)
  end

  def test_lookup_finds_methods_from_included_modules
    f = Foo.new
    assert_equal(f.say_hi,
                 Look.up(:say_hi, f).call)
  end
end

class TestSingletonMethods < MiniTest::Unit::TestCase
  class Food
    def initialize(kind, calories)
      @kind = kind
      @calories = calories
    end
  end

  def test_lookup_finds_singleton_methods
    bagel = Food.new("bagel", 100)
    pizza = Food.new("pizza", 1000)
    pizzabagel = Food.new("pizzabagel", 500)

    def bagel.tastes
      "alright, kinda bland"
    end
    def pizza.tastes
      "pretty good, kinda greasy"
    end
    def pizzabagel.tastes
      "amazing"
    end

    assert_equal(bagel.tastes,
                 Look.up(:tastes, bagel).call)
    assert_equal(pizza.tastes,
                 Look.up(:tastes, pizza).call)
    assert_equal(pizzabagel.tastes,
                 Look.up(:tastes, pizzabagel).call)
  end
end

class TestClassMethods < MiniTest::Unit::TestCase
  class Foo
    def self.foo!
      "Foo!"
    end
  end

  class Bar < Foo
    def self.bar!
      "Bar!"
    end
  end

  class Baz < Bar
    def self.baz!
      "Baz!"
    end
  end

  def test_lookup_finds_direct_class_methods
    assert_equal(Foo.foo!,
                 Look.up(:foo!, Foo).call)
    assert_equal(Bar.bar!,
                 Look.up(:bar!, Bar).call)
    assert_equal(Baz.baz!,
                 Look.up(:baz!, Baz).call)
  end

  def test_lookup_finds_ancestral_class_methods
    assert_equal(Bar.foo!,
                 Look.up(:foo!, Bar).call)
    assert_equal(Baz.foo!,
                 Look.up(:foo!, Baz).call)
    assert_equal(Baz.bar!,
                 Look.up(:bar!, Baz).call)
  end
end

class TestFunkyPrivateMethodStuff < MiniTest::Unit::TestCase
  def test_that_include_isnt_a_keyword
    assert(Look.up(:include, Class))
    assert(Look.up(:include, Module))
    assert_nil(Look.up(:include, Object.new))
  end
  def test_that_raise_isnt_a_keyword
    assert(Look.up(:raise, Object.new))
  end
end

class TestWeirdAncestors < MiniTest::Unit::TestCase
  class Utensil
    # Singleton classes include Kernel, which has its own #fork
    def fork
      "Utensil#fork!"
    end
  end

  def test_lookup_uses_the_right_ancestor_path
    u = Utensil.new
    assert_equal(u.fork, Look.up(:fork, u).call)
  end

  module M
    def say_hi
      "M#hi!"
    end
  end
  class A
    include M
  end
  class B < A
    def say_hi
      "B#say_hi"
    end
  end
  class C < B
    include M # Doesn't actually do anything! Doesn't overwrite B#say_hi!
  end

  def test_module_inclusion_looks_higher_up_the_chain
    b = B.new
    c = C.new
    assert_equal(c.say_hi, b.say_hi)
    assert_equal(c.say_hi,
                 Look.up(:say_hi, c).call)
  end
end
