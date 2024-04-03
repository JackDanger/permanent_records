# PermanentRecords

[http://github.com/JackDanger/permanent_records/](http://github.com/JackDanger/permanent_records/)

This gem prevents any of your ActiveRecord data from being destroyed.
Any model that you've given a "deleted_at" datetime column will have that column set rather than let the record be deleted.

## What methods does it give me?

```ruby
User.find(3).destroy          # Sets the 'deleted_at' attribute to Time.now
                              # and returns a frozen record. If halted by a
                              # before_destroy callback it returns false instead

User.find(3).destroy(:force)  # Executes the real destroy method, the record
                              # will be removed from the database.

User.destroy_all              # Soft-deletes all User records.

User.delete_all               # bye bye everything (no soft-deleting here)
```
There are also two scopes provided for easily searching deleted and not deleted records:

```ruby
User.deleted.find(...)        # Only returns deleted records.

User.not_deleted.find(...)    # Only returns non-deleted records.
```

Note: Your normal finds will, by default, _include_ deleted records. You'll have to manually use the ```not_deleted``` scope to avoid this:

```ruby
User.find(1)                  # Will find record number 1, even if it's deleted.

User.not_deleted.find(1)      # This is probably what you want, it doesn't find deleted records.
```

## Can I easily undelete records?

Yes. All you need to do is call the 'revive' method.

```ruby
User.find(3).destroy         # The user is now deleted.

User.find(3).revive          # The user is back to it's original state.
```

And if you had dependent records that were set to be destroyed along with the parent record:

```ruby
class User < ActiveRecord::Base
  has_many :comments, :dependent => :destroy
end

User.find(3).destroy         # All the comments are destroyed as well.

User.find(3).revive          # All the comments that were just destroyed
                             # are now back in pristine condition.
```

Forcing deletion works the same way: if you hard delete a record, its dependent records will also be hard deleted.

## Can I use default scopes?

```ruby
default_scope where(:deleted_at => nil)
```

If you use such a default scope, you will need to simulate the `deleted` scope with a method

```ruby
def self.deleted
  self.unscoped.where('deleted_at IS NOT NULL')
end
```

## Is Everything Automated?

Yes. You don't have to change ANY of your code to get permanent archiving of all your data with this gem.
When you call `destroy` on any record  (or `destroy_all` on a class or association) your records will
all have a deleted_at timestamp set on them.

## Upgrading from 3.x

The behaviour of the `destroy` method has been updated so that it now returns
`false` when halted by a before_destroy callback. This is in line with behaviour
of ActiveRecord. For more information see
[#47](https://github.com/JackDanger/permanent_records/issues/47).

## Productionizing

If you operate a system where destroying or reviving a record takes more
than about 3 seconds then you'll want to customize
`PermanentRecords.dependent_record_window = 10.seconds` or some other
value that works for you.

Patches welcome, forks celebrated.

Copyright 2015 Jack Danger Canty @ [https://jdanger.com](https://jdanger.com) released under the MIT license
