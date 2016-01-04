require 'spec_helper'

describe PermanentRecords do
  let(:hole) { dirt.hole }
  let!(:ant)  { hole.ants.create! }
  let(:dirt) { Dirt.create!.tap { |dirt| dirt.create_hole } }

  before { hole.destroy }

  describe '#revive' do

    it 'should revive parent first' do
      hole.revive(reverse: true)
    end
  end
end
