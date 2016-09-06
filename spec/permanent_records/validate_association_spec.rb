require 'spec_helper'

describe PermanentRecords do
  let(:house)  { House.create }
  let(:room)   { house.rooms.create }

  describe '#revive' do
    it "when child try to find his parent, it can't access to it due the default scope" do
      expect {
        house.destroy
      }.to change {
        room.reload.deleted?
      }.to(true)

      expect { house.revive }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: House can't be blank")
    end
  end
end
