# frozen_string_literal: true

require 'spec_helper'

describe PermanentRecords do
  let(:hole) { Hole.create }
  let(:dirt) { Dirt.create(hole: hole) }

  it 'have correct initial ants_count' do
    expect(hole.ants_count).to eq 0
  end

  describe 'polymorpic associations' do
    before do
      hole.poly_ants.create!
      hole.poly_ants.last.destroy!
    end

    it 'decrements counter_cache after destroying ant' do
      expect(hole.reload.ants_count).to eq(0)
    end

    context 'revive' do
      before do
        hole.poly_ants.deleted.first.revive
      end

      it 'increment counter_cache after reviving ant' do
        expect(hole.reload.ants_count).to eq(1)
      end
    end
  end

  describe 'counter cache' do
    before do
      hole.ants.create!
    end

    context 'increment' do
      before do
        hole.ants.create!
      end

      it 'increments counter_cache after creating new ant' do
        expect(hole.ants_count).to eq(2)
      end
    end

    context 'decrement' do
      before do
        hole.ants.last.destroy!
      end

      it 'decrements counter_cache after destroying ant' do
        expect(hole.reload.ants_count).to eq(0)
      end

      context 'revive' do
        before do
          hole.ants.deleted.first.revive
        end

        it 'increment counter_cache after reviving ant' do
          expect(hole.reload.ants_count).to eq(1)
        end
      end
    end
  end
end
