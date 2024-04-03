# frozen_string_literal: true

require 'spec_helper'

describe PermanentRecords do
  let(:hole) { Hole.create }
  let(:dirt) { Dirt.create(hole: hole) }
  let!(:ant) { hole.ants.create! }

  before { hole.destroy }

  describe '#revive' do
    subject(:revive) { hole.revive(reverse: true) }

    it 'revives parent first' do
      expect { revive }.not_to raise_error
    end
  end
end
