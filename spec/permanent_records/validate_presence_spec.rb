# frozen_string_literal: true

require 'spec_helper'

describe PermanentRecords do
  let(:house)  { House.create }
  let(:room)   { house.rooms.create }

  describe '#revive' do
    context 'child validate presence of parent' do
      it 'when you revive parent first children are revived although the default scope' do
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

      it 'it\'s impossible to revive children first when child validate presence of parent and have a default scope' do
        expect {
          house.destroy
        }.to change {
          house.reload.deleted?
        }.to(true) & change {
          room.reload.deleted?
        }.to(true)

        # Room Validation failed
        expect { house.revive }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: House can't be blank")
      end
    end
  end
end
