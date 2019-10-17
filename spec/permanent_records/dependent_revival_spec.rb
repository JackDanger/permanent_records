require 'spec_helper'

MUSKRATS_PER_HOLE = 3

describe PermanentRecords do
  let(:hole_a)   { Hole.create! }
  let(:hole_b)   { Hole.create! }

  before do
    # add muskrats to hole_a and hole_b
    MUSKRATS_PER_HOLE.times do
      hole_a.muskrats.create!
      hole_b.muskrats.create!
    end

    # destroy both holes
    hole_a.destroy
    hole_b.destroy

    # only revive one hole
    hole_a.revive
  end

  describe 'revive dependent associations, and only dependent associations' do
    it 'should revive muskrats of revived hole' do
      expect(hole_a.reload).to_not be_deleted
      expect(hole_a.muskrats.not_deleted.count).to eq MUSKRATS_PER_HOLE
    end

    it 'should not revive muskrats of non-revived hole' do
      expect(hole_b.reload).to     be_deleted
      expect(hole_b.muskrats.not_deleted.count).to eq 0
    end
  end
end
