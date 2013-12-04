<pre>
      Tame dem sour grapes with Razin----
                                                  .--------------. 
                                              .__/  ------  __    `---.        tame dem sour grapes with Razin------
                                             / * ------  ____   --*-   |       
                                            |  ______ *   *------  __  |
     ---Tame dem sour grapes with Razin      `--.  ____  _*_______ .__/
                                                 \________________/                ---tame dem sour grapes with Razin
</pre>

# Razin
Declare exception contracts in your Ruby code to express intent and aid in identifying programming errors. Stop tracing through methods to discover what a method could raise - start using exception contracts and just know.

## Why Use It?

Exception handling in Ruby is a sour experience; much is left up to the developer. Razin DRYs up all those sour grapes using a simple, lightweight, easy to understand pattern for expressing exception contracts. Using Razin, you can quickly reason about what goes on inside all of those methods you're calling; you'll know which exceptions are intended to be raised - everything else is a programming error. 


## Installation

Add this line to your application's Gemfile:

    gem 'razin'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install razin

## Usage

Say you have some method that does many a thing:

```ruby
  def gift_pooh
    book = LibraryService.checkout_book("Winnie the Pooh")
    
    wrapped_book = WrappingService.wrap(book)
    
    MailingService.mail(wrapped_book)
    
    record_gifted(book)
    
    book
  end
```

Each of the service calls could fail in a variety of ways. Let's say the LibraryService is a synchronous, external service that uses REST; the WrappingService is a synchronous, local service that uses a DB; the MailingService is an asynchronous local service; and finally, the record_gifted() method records statistics about the gifting process. 

Let's say the following errors are possible:

* LibraryService raises: Net::HTTPError, BookNotFound, BookNotAvailable.
* WrappingService raises: ConnectionError, OutOfWrappingPaper.
* MailingService raises SMTPConnectionError.
* The record_gifted() method raises StatisticsStoreOutOfSpaceError.

Let's say we want to classify all of these errors as failures: we could rewrite as:

```ruby
  class GiftingFailed < Nesty::NestedStandardError; end

  def gift_pooh
    # same as above
  rescue => e
    raise GiftingFailed
  end
```

However, doing this means that we are handling all errors the same way, regardless of type. This may be fine for the time being, but what happens when one of the services is changed to return a new error? Ideally, the services are nesting exceptions from underlying lower levels. The exception handling in the gift_pooh() method should express the intent of how to handle each of those cases and what each means w.r.t. to the behavior of the method. A rewrite, assuming each of the services are using nested exceptions:

```ruby
  class GiftingFailed < Nesty::NestedStandardError; end
  class GiftingCheckoutFailed < GiftingFailed; end
  class GiftingWrappingFailed < GiftingFailed; end
  class GiftingMailingFailed < GiftingFailed; end
  class GiftingRecordingStatisticsFailed < GiftingFailed; end

  def gift_pooh
    # same as above
  rescue LibraryService::CheckoutError
    raise GiftingCheckoutFailed
  rescue WrappingService::WrappingError
    raise GiftingWrappingFailed
  rescue MailingService::MailError
    raise GiftingMailingFailed
  rescue StatisticsRecordingError
    raise GiftingRecordingStatisticsFailed
  end
```

The Gifting* errors raised from the rescue blocks comprise the exception contract of the gift_pooh() method. The rescue-all statement (rescue => e) is no longer necessary as all the cases are handled. 

But... let's say a few commits down the line, the implementation changes and now a new exception can be raised - we need to upgrade our exception contract to handle it.
 

We could ignore errors that are not crucial to the task, for example:

```ruby
  class GiftingFailed < Nesty::NestedStandardError; end

  def gift_pooh
    # same as above
  rescue StatisticsStoreOutOfSpaceError
    # just ignore
  rescue => e
    raise GiftingFailed
  end
```

We may find that some of these errors are worth informing the caller about while others are not. Say we want to tell the caller about BookNotFound errors, but continue to nest all connection related failures under a general GiftingFailed error:

```ruby
  class GiftingFailed < Nesty::NestedStandardError; end

  def gift_pooh
    # same as above
  rescue BookNotFound
    # re-raise
    raise
  rescue StatisticsStoreOutOfSpaceError
    # just ignore
  rescue => e
    raise GiftingFailed
  end
```

But, what if we want to ignore some of these errors, say StatisticsStoreOutOfSpaceError

WIP


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
