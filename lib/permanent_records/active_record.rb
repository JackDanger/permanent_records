# frozen_string_literal: true

# Support destroy for rails belongs_to assocations.
module HandlePermanentRecordsDestroyedInBelongsToAssociation
  def handle_dependency
    return unless load_target

    # only patch :destroy case and delegate to super otherwise
    case options[:dependent]
    when :destroy
      target.destroy
      raise ActiveRecord::Rollback if target.respond_to?(:deleted?) && !target.deleted?
    else
      super
    end
  end
end

# Support destroy for rails has_one associations.
module HandlePermanentRecordsDestroyedInHasOneAssociation
  def delete(method = options[:dependent])
    return unless load_target

    # only patch :destroy case and delegate to super otherwise
    case method
    when :destroy
      target.destroyed_by_association = reflection
      target.destroy
      throw(:abort) if target.respond_to?(:deleted?) && !target.deleted?
    else
      super(method)
    end
  end
end
ActiveRecord::Associations::BelongsToAssociation.prepend(HandlePermanentRecordsDestroyedInBelongsToAssociation)
ActiveRecord::Associations::HasOneAssociation.prepend(HandlePermanentRecordsDestroyedInHasOneAssociation)
