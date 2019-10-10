module HandlePermanentRecordsDestroyedInBelongsToAssociation
  def handle_dependency
    return unless load_target

    case options[:dependent]
    when :destroy
      target.destroy
      raise ActiveRecord::Rollback if target.respond_to?(:deleted?) && !target.deleted?
    else
      target.send(options[:dependent])
    end
  end
end

module HandlePermanentRecordsDestroyedInHasOneAssociation
  def delete(method = options[:dependent])
    if load_target
      case method
      when :delete
        target.delete
      when :destroy
        target.destroyed_by_association = reflection
        target.destroy
        throw(:abort) if target.respond_to?(:deleted?) && !target.deleted?
      when :nullify
        target.update_columns(reflection.foreign_key => nil) if target.persisted?
      end
    end
  end
end

ActiveRecord::Associations::BelongsToAssociation.prepend HandlePermanentRecordsDestroyedInBelongsToAssociation
ActiveRecord::Associations::HasOneAssociation.prepend HandlePermanentRecordsDestroyedInHasOneAssociation
