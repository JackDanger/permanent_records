require 'spec_helper'

describe PermanentRecords do
  let(:hole) { dirt.hole }
  let(:dirt) { Dirt.create!.tap { |dirt| dirt.create_hole } }

  before { hole.destroy }

  describe '#revive' do

    before do
      expect(dirt).to receive(:get_deleted_record) { dirt }
      expect(dirt).to receive(:save).with(validate: false)
    end

    it 'should propagate validation flag on dependent records' do
      hole.revive(validate: false)
    end
  end
end
