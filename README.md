[![Build Status](https://travis-ci.org/dtognazzini/razin.png?branch=master)](https://travis-ci.org/dtognazzini/razin)

<pre>
  
             ..`````v'''~''''~.
          ._/  ------* __ ~~~~ `--.  
         / * ------  ____   --*-   \       
        |  ~~~~~~ *   ----*--  __ ./
         `--.  ----  _*_______ .__/
             `__~___~___.^.___/      
             
                                      ----tame dem sour grapes with Razin
</pre>

# Razin
Declare exception contracts in your Ruby code to express intent and aid in identifying programming errors. Stop tracing through methods to discover what a method could raise - start using exception contracts and just know.

## Why Use It?

Exception handling in Ruby is a sour experience; much is left up to the developer. Razin DRYs up all those sour grapes using a simple, lightweight, easy to understand pattern for expressing exception contracts. Using Razin, you can quickly reason about what goes on inside all of those methods you're calling; you'll know which exceptions are intended to be raised - everything else is a programming error. 

## Usage

Express exception contracts with ease...

```ruby
  class GiftingError              < Nesty::NestedStandardError; end
  class GiftingServiceUnavailable < GiftingError; end
  class GiftingBookError          < GiftingError; end
  
  def gift_book(book_name)
    Razin.raises(GiftingBookError, GiftingServiceUnavailable) do
      begin
      
        book = ExternalLibraryService.checkout_book(book_name)

        wrapped_book = WrappingService.wrap(book)

        MailingService.mail(wrapped_book)

        StatisticsService.record_gift_of(book)

        book    
    
      rescue ExternalLibraryService::BookCheckoutFailed
        raise GiftingBookError
      rescue ExternalLibraryService::CheckoutFailed, WrappingService::WrappingError, 
             MailingService::MailingError
        raise GiftingServiceUnavailable
      rescue StatisticsService::Error
        # ignore everything having to do with recording statistics
      end
    end
  end
```

Using Razin, gift_book() has a intentional, clearly expressed exception contract that is easy to read and reason about. Developers programming to gift_book() aren't burdened with sifting through the implementation to distill the contract - it's stated explicitly.

[Read more...](#background)


## Installation

Add this line to your application's Gemfile:

    gem 'razin'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install razin

## Background

Say you have some code to send books as gifts:

```ruby
  books_to_gift = ["Winnie The Pooh", "The Hobbit", "Beyond Good and Evil"]
  
  books_to_gift.each do |book_name|
    gift_book(book_name)
  end
```

And say, gift_book() does many a thing:

```ruby
  def gift_book(book_name)
    book = ExternalLibraryService.checkout_book(book_name)
    
    wrapped_book = WrappingService.wrap(book)
    
    MailingService.mail(wrapped_book)
    
    StatisticsService.record_gift_of(book)
    
    book
  end
```

Where:

* ExternalLibraryService is a synchronous, external service that uses REST.
* WrappingService is a synchronous, local service that uses a DB.
* MailingService is an asynchronous local service.
* StatisticsService records statistics to the file system.

Each of the service calls could fail in a variety of ways. Let's say the following errors are possible:

* ExternalLibraryService raises: ExternalLibraryService::ConnectionError, ExternalLibraryService::BookNotFound, ExternalLibraryService::BookNotAvailable.
* WrappingService raises: WrappingService::ConnectionError, WrappingService::OutOfWrappingPaper.
* MailingService raises MailingService::ConnectionError.
* StatisticsService raises StatisticsService::OutOfSpaceError.

### The problem...

Now, let's say that the code above would like to continue on gifting books in cases where the book is not found, but stop the entire process in the event that any of the services are down, like so:

```ruby
  books_to_gift = ["Winnie The Pooh", "The Hobbit", "Beyond Good and Evil"]
  
  books_to_gift.each do |book_name|
    begin
      gift_book(book_name)
    rescue ExternalLibraryService::BookNotFound, ExternalLibraryService::BookNotAvailable
      # ignore, and continue
    end
  end
```

In the above rewrite, the references to the ExternalLibraryService errors have resulted in a leaky abstraction. If gift_book() is updated later to use a LocalLibraryService instead of ExternalLibraryService, the calling code would need to be updated as well.

### Why nested exceptions...

We can address the leaky abstraction by mapping exceptions from the implementation to a new set of exceptions representing the failures cases of gift_book().

Here's a rewrite using [Nesty](https://github.com/skorks/nesty) for [Exception Chaining](http://en.wikipedia.org/wiki/Exception_chaining):

```ruby
  class GiftingServiceUnavailable < Nesty::NestedStandardError; end
  class GiftingBookError          < Nesty::NestedStandardError; end

  def gift_book(book_name)
    # same as above
    
  rescue ExternalLibraryService::BookNotFound, ExternalLibraryService::BookNotAvailable
    raise GiftingBookError
  rescue ExternalLibraryService::ConnectionError, WrappingService::ConnectionError, 
         WrappingService::OutOfWrappingPaper, MailingService::ConnectionError
    raise GiftingServiceUnavailable
  rescue StatisticsService::OutOfSpaceError
    # ignore
  end
```

The above rewrite maps ExternalLibraryService's BookNotFound and BookNotAvailable to GiftingBookError, ignores errors that occur when tracking statistics through the StatisticsService, and maps all other errors that could occur across the services to a generic GiftingServiceUnavailable exception. 

The calling code can now be written without referencing the implementation details of gift_book():

```ruby
  books_to_gift = ["Winnie The Pooh", "The Hobbit", "Beyond Good and Evil"]
  
  books_to_gift.each do |book_name|
    begin
      gift_book(book_name)
    rescue GiftingBookError
      # ignore, and continue
    end
  end
```

The exception handling in the above calling code is dependent on the exception interface/contract of gift_book(). If gift_book() is updated to raise new exceptions, the code above may need to be updated with handling.

### Why exception contracts...

So far, gift_book() does absolutely nothing to ensure that the interface doesn't change. If a new exception is raised by one of the services it uses, gift_book() will raise it to its callers, resulting in another leaky abstraction. To ensure this doesn't happen, gift_books() can use a rescue-all statement to wrap unhandled exceptions under a generic failed error:
  
```ruby
  # the generic error
  class GiftingError              < Nesty::NestedStandardError; end
  
  class GiftingServiceUnavailable < GiftingError; end
  class GiftingBookError          < GiftingError; end

  def gift_book(book_name)
    # same as above
    
  rescue ExternalLibraryService::BookNotFound, ExternalLibraryService::BookNotAvailable
    raise GiftingBookError
  rescue ExternalLibraryService::ConnectionError, WrappingService::ConnectionError, 
         WrappingService::OutOfWrappingPaper, MailingService::ConnectionError
    raise GiftingServiceUnavailable
  rescue StatisticsService::OutOfSpaceError
    # ignore
  rescue 
    raise GiftingError
  end
```

The rescue-all statement in the above code says that "any number of other errors could happen, and they all indicate that gifting failed." This may be true today, but not tomorrow. Wrapping any number of unknown errors under GiftingError provides nearly no information to the caller. The caller either has to handle all errors nested under GiftingError the same way or reach into the GiftingError and look at the wrapped error to make decisions; the first option doesn't provide the caller with much choice on how to handle errors and the second option is another leaky abstraction.

### Better than rescue-and-nest-all...

gift_book() should provide a high fidelity exception contract whereby all the failure modes are represented and none of its implementation details are leaked. Additionally, gift_book() should provide an easy way for calling code to classify and handle the various failure modes. 

These requirements are easy to satisfy via:

* Use a new error for wrapping unexpected errors
* Continue to use a base error class for callers to classify.

```ruby
  class UnexpectedError           < Nesty::NestedStandardError; end
  
  class GiftingError              < Nesty::NestedStandardError; end
  class GiftingServiceUnavailable < GiftingError; end
  class GiftingBookError          < GiftingError; end

  def gift_book(book_name)
    # same as above
    
  rescue ExternalLibraryService::BookNotFound, ExternalLibraryService::BookNotAvailable
    raise GiftingBookError
  rescue ExternalLibraryService::CheckoutError, WrappingService::ConnectionError, 
         WrappingService::OutOfWrappingPaper, MailingService::ConnectionError
    raise GiftingServiceUnavailable
  rescue StatisticsService::OutOfSpaceError
    # ignore
  rescue 
    raise UnexpectedError
  end
```

### Contracts on top of contracts...

With the above, the exception contract for gift_book() is complete. 

Here is a rewrite of gift_book() assuming the services used in the implementation follow the same pattern:

```ruby
  # same exception classes as above
  
  def gift_book(book_name)
    # same as above
    
  rescue ExternalLibraryService::BookCheckoutFailed
    raise GiftingBookError
  rescue ExternalLibraryService::CheckoutFailed, WrappingService::WrappingError, 
         MailingService::MailingError
    raise GiftingServiceUnavailable
  rescue StatisticsService::Error
    # ignore everything having to do with recording statistics
  rescue 
    raise UnexpectedError
  end
```

### Taming grapes...

Razin encapsulates the exception contract implementation pattern derived above. 

Here is the gift_book() rewritten to use Razin:

```ruby
  # same exception classes as above
  
  def gift_book(book_name)
    Razin.raises(GiftingBookError, GiftingServiceUnavailable) do
      begin
        # same as above
    
      rescue ExternalLibraryService::BookCheckoutFailed
        raise GiftingBookError
      rescue ExternalLibraryService::CheckoutFailed, WrappingService::WrappingError, 
             MailingService::MailingError
        raise GiftingServiceUnavailable
      rescue StatisticsService::Error
        # ignore everything having to do with recording statistics
      end
    end
  end
```

Using Razin, gift_book() has a intentional, clearly expressed exception contract that is easy to read and reason about. Developers programming to gift_book() aren't burdened with sifting through the implementation to distill the contract - it's stated explicitly.

So sweet...

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
