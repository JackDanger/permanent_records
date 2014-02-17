require 'spec_helper'

describe PermanentRecords do

  let!(:frozen_moment) { Time.now                            }
  let!(:dirt)          { Dirt.create!                        }
  let!(:earthworm)     { dirt.create_earthworm               }
  let!(:hole)          { dirt.create_hole                    }
  let!(:muskrat)       { hole.muskrats.create!               }
  let!(:mole)          { hole.moles.create!                  }
  let!(:location)      { hole.create_location                }
  let!(:difficulty)    { hole.create_difficulty              }
  let!(:comments)      { 2.times.map {hole.comments.create!} }
  let!(:kitty)         { Kitty.create!                       }


  describe '#destroy' do

    let(:record)       { hole    }
    let(:should_force) { false   }

    subject { record.destroy should_force }

    it 'returns the record' do
      subject.should == record
    end

    it 'makes deleted? return true' do
      subject.should be_deleted
    end

    it 'sets the deleted_at attribute' do
      subject.deleted_at.should be_within(0.1).of(Time.now)
    end

    it 'does not really remove the record' do
      expect { subject }.to_not change { record.class.count }
    end

    it 'handles serialized attributes correctly' do
      expect { subject.options }.to_not raise_error
      expect { subject.size }.to_not raise_error if record.respond_to?(:size)
    end

    context 'with force argument set to truthy' do
      let(:should_force) { :force }

      it 'does really remove the record' do
        expect { subject }.to change { record.class.count }.by(-1)
      end
    end

    context 'with hash-style :force argument' do
      let(:should_force) {{ force: true }}

      it 'does really remove the record' do
        expect { subject }.to change { record.class.count }.by(-1)
      end
    end

    context 'when validations fail' do
      before {
        Hole.any_instance.stub(:valid?).and_return(false)
      }
      it 'raises' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end

      context 'with validation opt-out' do
        let(:should_force) {{ validate: false }}
        it 'doesnt raise' do
          expect { subject }.to_not raise_error
        end
        it 'soft-deletes the invalid record' do
          subject.should be_deleted
        end
      end
    end


    context 'when model has no deleted_at column' do
      let(:record) { kitty }

      it 'really removes the record' do
        expect { subject }.to change { record.class.count }.by(-1)
      end
    end

    context 'with dependent records' do
      context 'that are permanent' do
        it '' do
          expect { subject }.to_not change { Muskrat.count }
        end

        context 'with has_many cardinality' do
          it 'marks records as deleted' do
            subject.muskrats.each {|m| m.should be_deleted }
          end
          context 'with force delete' do
            let(:should_force) { :force }
            it('') { expect { subject }.to change { Muskrat.count }.by(-1) }
            it('') { expect { subject }.to change { Comment.count }.by(-2) }
          end
        end

        context 'with has_one cardinality' do
          it 'marks records as deleted' do
            subject.location.should be_deleted
          end
          context 'with force delete' do
            let(:should_force) { :force }
            it('') { expect { subject }.to change { Muskrat.count  }.by(-1) }
            it('') { expect { subject }.to change { Location.count }.by(-1) }
          end
        end
      end
      context 'that are non-permanent' do
        it 'removes them' do
          expect { subject }.to change { Mole.count }.by(-1)
        end
      end
      context 'as default scope' do
        let(:load_comments) { Comment.unscoped.where(:hole_id => subject.id) }
        context 'with :has_many cardinality' do
          before {
            load_comments.size.should == 2
          }
          it 'deletes them' do
            load_comments.all?(&:deleted?).should be_true
            # Doesn't change the default scope
            # (in versions with non-broken default scope)
            if ActiveRecord::VERSION::STRING > '3.0.0'
              subject.comments.should be_blank
            end
          end
        end
        context 'with :has_one cardinality' do
          it 'deletes them' do
            subject.difficulty.should be_deleted
            Difficulty.find_by_id(subject.difficulty.id).should be_nil
          end
        end
      end
    end
  end

  describe '#revive' do

    let!(:record) { hole.destroy }
    let(:should_validate) { nil  }

    subject { record.revive should_validate }

    it 'returns the record' do
      subject.should == record
    end

    it 'unsets deleted_at' do
      expect { subject }.to change {
        record.deleted_at
      }.to(nil)
    end

    it 'makes deleted? return false' do
      subject.should_not be_deleted
    end

    context 'when validations fail' do
      before {
        Hole.any_instance.stub(:valid?).and_return(false)
      }
      it 'raises' do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end

      context 'with validation opt-out' do
        let(:should_validate) {{ validate: false }}
        it 'doesnt raise' do
          expect { subject }.to_not raise_error
        end
        it 'makes deleted? return false' do
          subject.should_not be_deleted
        end
      end
    end

    context 'with dependent records' do
      context 'that are permanent' do
        it '' do
          expect { subject }.to_not change { Muskrat.count }
        end

        context 'that were deleted previously' do
          before { muskrat.update_attributes! :deleted_at => 2.minutes.ago }
          it 'does not restore' do
            expect { subject }.to_not change { muskrat.deleted? }
          end
        end

        context 'with has_many cardinality' do
          it 'revives them' do
            subject.muskrats.each {|m| m.should_not be_deleted }
          end
        end

        context 'with has_one cardinality' do
          it 'revives them' do
            subject.location.should_not be_deleted
          end
        end
      end
      context 'that are non-permanent' do
        it 'cannot revive them' do
          expect { subject }.to_not change { Mole.count }
        end
      end
      context 'as default scope' do
        context 'with :has_many cardinality' do
          its('comments.size') { should == 2 }
          it 'revives them' do
            subject.comments.each {|c| c.should_not be_deleted }
            subject.comments.each {|c| Comment.find_by_id(c.id).should == c }
          end
        end
        context 'with :has_one cardinality' do
          it 'revives them' do
            subject.difficulty.should_not be_deleted
            Difficulty.find_by_id(subject.difficulty.id).should == difficulty
          end
        end
      end
    end
  end

  describe 'scopes' do

    before {
      3.times { Muskrat.create! }
      6.times { Muskrat.create!.destroy }
    }

    context '.not_deleted' do

      it 'counts' do
        Muskrat.not_deleted.count.should == Muskrat.all.reject(&:deleted?).size
      end

      it 'has no deleted records' do
        Muskrat.not_deleted.each {|m| m.should_not be_deleted }
      end
    end

    context '.deleted' do
      it 'counts' do
        Muskrat.deleted.count.should == Muskrat.all.select(&:deleted?).size
      end

      it 'has no non-deleted records' do
        Muskrat.deleted.each {|m| m.should be_deleted }
      end
    end
  end
end
