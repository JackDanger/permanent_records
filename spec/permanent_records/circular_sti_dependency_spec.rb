require 'spec_helper'

describe PermanentRecords do
  let(:hole)     { dirt.hole }
  let(:dirt)     { Dirt.create!.tap(&:create_hole) }
  let(:location) { Location.create(name: 'location', hole: hole) }
  let!(:zone) do
    location.zones.create name: 'zone', parent_id: location.id
  end

  before do
    hole.destroy
  end

  describe '#revive' do
    it 'should revive children properly on STI' do
      expect(hole.reload).to     be_deleted
      expect(dirt.reload).to     be_deleted
      expect(location.reload).to be_deleted
      expect(zone.reload).to     be_deleted
      hole.revive
      expect(hole.reload).to_not     be_deleted
      expect(dirt.reload).to_not     be_deleted
      expect(location.reload).to_not be_deleted
      expect(zone.reload).to_not     be_deleted
    end
  end
end
