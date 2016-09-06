require 'spec_helper'

describe PermanentRecords do
  let(:hole) { Hole.create }
  let(:dirt) { Dirt.create(hole: hole) }
  let!(:ant) { hole.ants.create! }

  before { hole.destroy }

  describe '#revive' do
    it 'should revive parent first' do
      hole.revive(reverse: true)
    end
  end
end
