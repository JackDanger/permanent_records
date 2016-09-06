require 'spec_helper'

describe PermanentRecords do
  let(:house)  { House.create }
  let(:room)   { house.rooms.create }

  describe '#revive' do
    context 'child validate presence of parent' do
      it 'when parent is revived, he cant see his children due the default scope' do
        expect {
          house.destroy
        }.to change {
          house.reload.deleted?
        }.to(true) & change {
          room.reload.deleted?
        }.to(true)

        expect {
          house.revive(reverse: true)
        }.to_not change {
          room.reload.deleted?
        }
      end
    end
  end
end
