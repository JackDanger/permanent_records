require 'spec_helper'

describe PermanentRecords do
  let(:house)  { House.create }
  let(:room)   { house.rooms.create }

  describe '#revive' do
    it 'when child validate presence of parent' do
      expect {
        house.destroy
      }.to change {
        house.reload.deleted?
      }.to(true) & change {
        room.reload.deleted?
      }.to(true)

      expect {
        house.revive(reverse: true)
      }.to change {
        house.reload.deleted?
      }.to(false) & change {
        room.reload.deleted?
      }.to(false)
    end
  end
end
