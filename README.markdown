# PermanentRecords

[http://github.com/JackDanger/permanent_records/](http://github.com/JackDanger/permanent_records/)

This gem prevents any of your ActiveRecord data from being destroyed.
Any model that you've given a "deleted_at" datetime column will have that column set rather than let the record be deleted.

## Compatability: This gem works with Rails versions 1, 2, and 3

## Does it make a lot of sense?

Yes.

```ruby
    User.find(3).destroy          # sets the 'deleted_at' attribute to Time.now and returns a frozen record
    User.find(3).destroy(:force)  # executes the real destroy method, the record will be removed from the database
    User.destroy_all              # soft-deletes all User records
    User.delete_all               # bye bye everything (no soft-deleting here)
```
There are also two scopes provided for easily searching deleted and not deleted records:

```ruby
    User.deleted.find(...)        # only returns deleted records.
    User.not_deleted.find(...)    # only returns non-deleted records.
```

Note: Your normal finds will, by default, _include_ deleted records. You'll have to manually use the 'not_deleted' scope to avoid this:

```ruby
    User.find(1)                  # will find record number 1, even if it's deleted
    User.not_deleted.find(1)      # This is probably what you want, it doesn't find deleted records
```

## Is Everything Automated?


Yes. You don't have to change ANY of your code to get permanent archiving of all your data with this gem. 
When you call 'destroy' on any record  (or 'destroy_all' on a class or association) your records will
all have a deleted_at timestamp set on them.


## Can I easily undelete records?

Yes. All you need to do is call the 'revive' method.

```ruby
    User.find(3).destroy
    # the user is now deleted
    User.find(3).revive
    # the user is back to it's original state
```

And if you had dependent records that were set to be destroyed along with the parent record:

```ruby
    class User < ActiveRecord::Base
      has_many :comments, :dependent => :destroy
    end
    User.find(3).destroy
    # all the comments are destroyed as well
    User.find(3).revive
    # all the comments that were just destroyed are now back in pristine condition
    
    # forcing deletion works the same way: fi you hard delete a record, its dependent records will also be hard deleted
```

## Can I use default scopes?

In Rails 3, yes.

```ruby
    default_scope where(:deleted_at => nil)
```

If you use such a default scope, you will need to simulate the `deleted` scope with a method

```ruby
    def self.deleted
      self.unscoped.where('deleted_at IS NOT NULL')
    end
```

Rails 2 provides no practical means of overriding default scopes (aside from using something like `Model.with_exclusive_scope { find(id) }`), so you'll need to implement those yourself if you need them.

Patches welcome, forks celebrated.

Copyright (c) 2010 Jack Danger Canty @ [http://jåck.com](http://jåck.com) of Cloops Inc., released under the MIT license
