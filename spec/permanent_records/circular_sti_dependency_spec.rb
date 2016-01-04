require 'pry'

require 'spec_helper'

describe PermanentRecords do
  let(:hole)      { dirt.hole }
  let(:dirt)      { Dirt.create!.tap { |dirt| dirt.create_hole } }
  let!(:location) { Location.create({name: 'location', hole: hole})  }
  let!(:zone)     { location.zones.create({name: 'zone', parent_id: location.id, hole: hole}) }

  before do
    hole.destroy({validate: false})
  end

  describe '#revive' do

    it 'should revive children properly on STI' do
      expect(hole.reload).to     be_deleted
      expect(dirt.reload).to     be_deleted
      expect(location.reload).to be_deleted
      # expect(hole.location.zones.deleted).to be_exists # STI relations isn't delete

      hole.revive

      expect(hole.reload).to_not     be_deleted
      expect(dirt.reload).to_not     be_deleted
      expect(location.reload).to_not be_deleted
      expect(hole.location.zones.not_deleted).to be_exists
    end
  end
end
