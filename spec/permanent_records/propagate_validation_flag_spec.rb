# frozen_string_literal: true

require 'spec_helper'

describe PermanentRecords do
  let(:hole) { Hole.create }
  let(:dirt) { Dirt.create(hole: hole) }

  before { hole.destroy }

  describe '#revive' do
    subject(:revive) { hole.revive(validate: false) }

    it 'propagates validation flag on dependent records' do
      allow(dirt).to receive(:get_deleted_record) { dirt }
      expect(dirt).to receive(:save).with(validate: false)
      revive
    end
  end
end
