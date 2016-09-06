require 'spec_helper'

describe PermanentRecords do
  let(:hole)     { Hole.create }
  let(:dirt)     { Dirt.create(hole: hole) }
  let(:location) { Location.create(name: 'location', hole: hole) }
  let!(:zone) do
    location.zones.create name: 'zone', parent_id: location.id
  end

  describe '#revive' do
    it 'should revive children properly on STI' do
      expect {
        hole.destroy
      }.to change {
        hole.reload.deleted?
      }.to(true) & change {
        dirt.reload.deleted?
      }.to(true) & change {
        location.reload.deleted?
      }.to(true) & change {
        zone.reload.deleted?
      }.to(true)

      expect {
        hole.revive
      }.to change {
        hole.reload.deleted?
      }.to(false) & change {
        dirt.reload.deleted?
      }.to(false) & change {
        location.reload.deleted?
      }.to(false) & change {
        zone.reload.deleted?
      }.to(false)
    end
  end
end
