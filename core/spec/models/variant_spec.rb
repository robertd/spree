require 'spec_helper'

describe Variant do
  let(:variant) { Variant.new(:count_on_hand => 95) }

  context "on_hand=" do
    before { variant.stub(:inventory_units => mock('inventory-units')) }

    context "when :track_inventory_levels is true" do
      before { Spree::Config.set :track_inventory_levels => true }

      context "and count is increased" do
        before { variant.inventory_units.stub(:with_state).and_return([]) }
        let(:inventory_unit) { mock_model(InventoryUnit, :state => "backordered") }

        it "should change count_on_hand to given value" do
          variant.on_hand = 100
          variant.count_on_hand.should == 100
        end

        it "should check for backordered units" do
          variant.inventory_units.should_receive(:with_state).with("backordered")
          variant.on_hand = 100
        end

        it "should fill 1 backorder when count_on_hand is zero" do
          variant.count_on_hand = 0
          variant.inventory_units.stub(:with_state).and_return([inventory_unit])
          inventory_unit.should_receive(:fill_backorder)
          variant.on_hand = 100
          variant.count_on_hand.should == 99
        end

        it "should fill multiple backorders when count_on_hand is negative" do
          variant.count_on_hand = -5
          variant.inventory_units.stub(:with_state).and_return(Array.new(5, inventory_unit))
          inventory_unit.should_receive(:fill_backorder).exactly(5).times
          variant.on_hand = 100
          variant.count_on_hand.should == 95
        end

      end

      context "and count is decreased" do
        before { variant.inventory_units.stub(:with_state).and_return([]) }

        it "should change count_on_hand to given value" do
          variant.on_hand = 10
          variant.count_on_hand.should == 10
        end

        it "should not check for backordered units" do
          variant.inventory_units.should_not_receive(:with_state)
          variant.on_hand = 10
        end

      end

    end

    context "when :track_inventory_levels is false" do
      before { Spree::Config.set :track_inventory_levels => false }

      it "should raise an exception" do
        lambda { variant.on_hand = 100 }.should raise_error
      end

    end

  end

  context "on_hand" do
    context "when :track_inventory_levels is true" do
      before { Spree::Config.set :track_inventory_levels => true }

      it "should return count_on_hand" do
        variant.on_hand.should == variant.count_on_hand
      end
    end

    context "when :track_inventory_levels is false" do
      before { Spree::Config.set :track_inventory_levels => false }

      it "should return nil" do
        variant.on_hand.should == nil
      end

    end

  end

  context "in_stock?" do
    context "when :track_inventory_levels is true" do
      before { Spree::Config.set :track_inventory_levels => true }

      it "should be true when count_on_hand is positive" do
        variant.in_stock?.should be_true
      end

      it "should be false when count_on_hand is zero" do
        variant.stub(:count_on_hand => 0)
        variant.in_stock?.should be_false
      end

      it "should be false when count_on_hand is negative" do
        variant.stub(:count_on_hand => -10)
        variant.in_stock?.should be_false
      end
    end

    context "when :track_inventory_levels is false" do
      before { Spree::Config.set :track_inventory_levels => false }

      it "should be true" do
        variant.in_stock?.should be_true
      end

    end

  end
end
