# frozen_string_literal: true

# rubocop:disable Performance/TimesMap
require 'spec_helper'

describe PermanentRecords do
  let!(:dirt)       { Dirt.create!                          }
  let!(:earthworm)  { dirt.create_earthworm                 }
  let!(:hole)       { dirt.create_hole(options: {})         }
  let!(:muskrat)    { hole.muskrats.create!                 }
  let!(:mole)       { hole.moles.create!                    }
  let!(:location)   { hole.create_location                  }
  let!(:difficulty) { hole.create_difficulty                }
  let!(:comments)   { 2.times.map { hole.comments.create! } }
  let!(:bed)        { Bed.create!                           }
  let!(:kitty)      { Kitty.create!(beds: [bed]) }
  let!(:meerkat)    { Meerkat.create!(holes: [hole]) }

  describe '#destroy' do
    subject { record.destroy(should_force) }

    let(:record)       { hole    }
    let(:should_force) { false   }

    it 'returns the record' do
      expect(subject).to eq(record)
    end

    it 'makes deleted? return true' do
      expect(subject).to be_deleted
    end

    it 'sets the deleted_at attribute' do
      expect(subject.deleted_at).to be_within(0.1).of(Time.now)
    end

    it 'does not really remove the record' do
      expect { subject }.not_to change(record.class, :count)
    end

    it 'handles serialized attributes correctly' do
      expect(subject.options).to eq({})
      expect(subject.size).to be_nil if record.respond_to?(:size)
    end

    context 'with force argument set to truthy' do
      let(:should_force) { :force }

      it 'does really remove the record' do
        expect { subject }.to change { record.class.count }.by(-1)
      end
    end

    context 'with hash-style :force argument' do
      let(:should_force) { { force: true } }

      it 'does really remove the record' do
        expect { subject }.to change { record.class.count }.by(-1)
      end
    end

    context 'when validations fail' do
      before do
        allow_any_instance_of(Hole).to receive(:valid?).and_return(false)
      end

      it 'raises' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end

      context 'with validation opt-out' do
        let(:should_force) { { validate: false } }

        it 'doesnt raise' do
          expect { subject }.not_to raise_error
        end

        it 'soft-deletes the invalid record' do
          expect(subject).to be_deleted
        end
      end
    end

    context 'when before_destroy returns false' do
      before do
        record.youre_in_the_hole = true
      end

      it 'returns false' do
        expect(subject).to be(false)
      end

      it 'does not set deleted_at' do
        expect { subject }.not_to change(record, :deleted_at)
      end

      context 'and using the !' do
        it 'raises a ActiveRecord::RecordNotDestroyed exception' do
          expect do
            record.destroy!
          end.to raise_error(ActiveRecord::RecordNotDestroyed)
        end
      end
    end

    context 'with dependent records' do
      context 'that are permanent' do
        it { expect { subject }.not_to change(Muskrat, :count) }

        context 'with has_many cardinality' do
          it 'marks records as deleted' do
            expect(subject.muskrats).to all(be_deleted)
          end

          context 'when error occurs' do
            before { allow_any_instance_of(Hole).to receive(:valid?).and_return(false) }

            it 'does not mark records as deleted' do
              expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
              expect(record.muskrats.not_deleted.count).to eq(1)
            end
          end

          context 'with force delete' do
            let(:should_force) { :force }

            it { expect { subject }.to change(Muskrat, :count).by(-1) }
            it { expect { subject }.to change(Comment, :count).by(-2) }

            context 'when error occurs' do
              before do
                allow_any_instance_of(Difficulty).to receive(:destroy).and_raise(ActiveRecord::RecordNotDestroyed)
              end

              it { expect { subject }.not_to change(Muskrat, :count) }
              it { expect { subject }.not_to change(Comment, :count) }
            end
          end
        end

        context 'with has_one cardinality' do
          it 'marks records as deleted' do
            expect(subject.location).to be_deleted
          end

          context 'when error occurs' do
            before { allow_any_instance_of(Hole).to receive(:valid?).and_return(false) }

            it('does not mark records as deleted') do
              expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
              expect(record.reload.location).not_to be_deleted
            end
          end

          context 'with force delete' do
            let(:should_force) { :force }

            it { expect { subject }.to change(Muskrat, :count).by(-1) }
            it { expect { subject }.to change(Location, :count).by(-1) }

            context 'when error occurs' do
              before do
                allow_any_instance_of(Difficulty).to receive(:destroy).and_raise(ActiveRecord::RecordNotDestroyed)
              end

              it { expect { subject }.not_to change(Muskrat, :count) }
              it { expect { subject }.not_to change(Location, :count) }
            end
          end
        end

        context 'with belongs_to cardinality' do
          it 'marks records as deleted' do
            expect(subject.dirt).to be_deleted
          end

          context 'when error occurs' do
            before { allow_any_instance_of(Hole).to receive(:valid?).and_return(false) }

            it 'does not mark records as deleted' do
              expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
              expect(record.dirt).not_to be_deleted
            end
          end

          context 'with force delete' do
            let(:should_force) { :force }

            it { expect { subject }.to change(Dirt, :count).by(-1) }

            context 'when error occurs' do
              before do
                allow_any_instance_of(Difficulty).to receive(:destroy).and_raise(ActiveRecord::RecordNotDestroyed)
              end

              it { expect { subject }.not_to change(Dirt, :count) }
            end
          end
        end
      end

      context 'that are non-permanent' do
        it 'removes them' do
          expect { subject }.to change(Mole, :count).by(-1)
        end

        context 'with has many cardinality' do
          context 'when model has no deleted_at column' do
            let(:record) { kitty }

            it 'really removes the record' do
              expect { subject }.to change { record.class.count }.by(-1)
            end

            it 'really removes the associations' do
              expect { subject }.to change(Bed, :count).by(-1)
            end

            it 'makes deleted? return true' do
              expect(subject).to be_deleted
            end
          end
        end
      end

      context 'as default scope' do
        let(:load_comments) { Comment.unscoped.where(hole_id: subject.id) }

        context 'with :has_many cardinality' do
          it 'deletes them' do
            expect(load_comments.size).to eq(2)
            expect(load_comments).to be_all(&:deleted?)
            expect(subject.comments).to be_blank
          end
        end

        context 'with :has_one cardinality' do
          it 'deletes them' do
            expect(subject.difficulty).to be_deleted
            expect(Difficulty.find_by_id(subject.difficulty.id)).to be_nil
          end
        end
      end
    end

    context 'with habtm association' do
      it 'does not remove the associated records' do
        expect { subject }.not_to change(Muskrat, :count)
      end

      it 'does not remove the entry from the join table' do
        expect { subject }.not_to change(meerkat.holes, :count)
      end

      context 'with force argument set to truthy' do
        let(:should_force) { :force }

        it 'does not remove the associated records' do
          expect { subject }.not_to change(Meerkat, :count)
        end

        it 'removes the entry from the join table' do
          expect { subject }.to change { meerkat.holes.count }.by(-1)
        end
      end
    end
  end

  describe '#revive' do
    subject { record.revive should_validate }

    let!(:record) { hole.tap(&:destroy) }
    let(:should_validate) { nil }

    it 'returns the record' do
      expect(subject).to eq(record)
    end

    it 'unsets deleted_at' do
      expect { subject }.to change(record, :deleted_at).to(nil)
    end

    it 'makes deleted? return false' do
      expect(subject).not_to be_deleted
    end

    context 'when validations fail' do
      before do
        allow_any_instance_of(Hole).to receive(:valid?).and_return(false)
      end

      it 'raises' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end

      context 'with validation opt-out' do
        let(:should_validate) { { validate: false } }

        it 'doesnt raise' do
          expect { subject }.not_to raise_error
        end

        it 'makes deleted? return false' do
          expect(subject).not_to be_deleted
        end
      end
    end

    context 'with dependent records' do
      context 'that are permanent' do
        it { expect { subject }.not_to change(Muskrat, :count) }

        context 'that were deleted previously' do
          before { muskrat.update_attribute :deleted_at, 2.minutes.ago }

          it 'does not restore' do
            expect { subject }.not_to change(muskrat, :deleted?)
          end
        end

        context 'with has_many cardinality' do
          it 'revives them' do
            subject.muskrats.each { |m| expect(m).not_to be_deleted }
          end

          context 'when error occurs' do
            before { allow_any_instance_of(Hole).to receive(:valid?).and_return(false) }

            it 'does not revive them' do
              expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
              expect(record.muskrats.deleted.count).to eq(1)
            end
          end
        end

        context 'with has_one cardinality' do
          it 'revives them' do
            expect(subject.location).not_to be_deleted
          end

          context 'when error occurs' do
            before { allow_any_instance_of(Hole).to receive(:valid?).and_return(false) }

            it('does not mark records as deleted') do
              expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
              expect(record.location).to be_deleted
            end
          end
        end

        context 'with belongs_to cardinality' do
          it 'revives them' do
            expect(subject.dirt).not_to be_deleted
          end

          context 'when error occurs' do
            before { allow_any_instance_of(Hole).to receive(:valid?).and_return(false) }

            it 'does not revive them' do
              expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
              expect(record.dirt).to be_deleted
            end
          end
        end
      end

      context 'that are non-permanent' do
        it 'cannot revive them' do
          expect { subject }.not_to change(Mole, :count)
        end
      end

      context 'as default scope' do
        context 'with :has_many cardinality' do
          describe '#comments' do
            subject { super().comments }

            describe '#size' do
              subject { super().size }

              it { is_expected.to eq(2) }
            end
          end

          it 'revives them' do
            subject.comments.each { |c|
              expect(c).not_to be_deleted
              expect(Comment.find_by_id(c.id)).to eq(c)
            }
          end
        end

        context 'with :has_one cardinality' do
          it 'revives them' do
            expect(subject.difficulty).not_to be_deleted
            expect(Difficulty.find_by_id(subject.difficulty.id)).to eq(difficulty)
          end
        end
      end
    end

    context 'with habtm association' do
      it 'does not change entries from the join table' do
        expect { subject }.not_to change(meerkat.holes, :count)
      end
    end
  end

  describe 'scopes' do
    before do
      3.times { Muskrat.create!(hole: hole) }
      6.times { Muskrat.create!(hole: hole).destroy }
    end

    describe '.not_deleted' do
      it 'counts' do
        expect(Muskrat.not_deleted.count).to eq(Muskrat.all.count { |element| !element.deleted? })
      end

      it 'has no deleted records' do
        Muskrat.not_deleted.each { |m| expect(m).not_to be_deleted }
      end
    end

    describe '.deleted' do
      it 'counts' do
        expect(Muskrat.deleted.count).to eq(Muskrat.all.count(&:deleted?))
      end

      it 'has no non-deleted records' do
        expect(Muskrat.deleted).to all(be_deleted)
      end
    end
  end
end
# rubocop:enable Performance/TimesMap
