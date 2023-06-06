import 'dart:async';

import 'defer.dart';

/// A utility class that provides static methods to create the various Streams
/// provided by RxDart.
///
/// ### Example
///
///      Rx.combineLatest([
///        Stream.value('a'),
///        Stream.fromIterable(['b', 'c', 'd'])
///      ], (list) => list.join())
///      .listen(print); // prints 'ab', 'ac', 'ad'
///
/// ### Learning RxDart
///
/// This library contains documentation and examples for each method. In
/// addition, more complex examples can be found in the
/// [RxDart github repo](https://github.com/ReactiveX/rxdart) demonstrating how
/// to use RxDart with web, command line, and Flutter applications.
///
/// #### Additional Resources
///
/// In addition to the RxDart documentation and examples, you can find many
/// more articles on Dart Streams that teach the fundamentals upon which
/// RxDart is built.
///
///   - [Asynchronous Programming: Streams](https://www.dartlang.org/tutorials/language/streams)
///   - [Single-Subscription vs. Broadcast Streams](https://dart.dev/tutorials/language/streams#two-kinds-of-streams)
///   - [Creating Streams in Dart](https://www.dartlang.org/articles/libraries/creating-streams)
///   - [Testing Streams: Stream Matchers](https://pub.dartlang.org/packages/test#stream-matchers)
///
/// ### Dart Streams vs Traditional Rx Observables
/// In ReactiveX, the Observable class is the heart of the ecosystem.
/// Observables represent data sources that emit 'items' or 'events' over time.
/// Dart already includes such a data source: Streams.
///
/// In order to integrate fluently with the Dart ecosystem, Rx Dart does not
/// provide a [Stream] class, but rather adds functionality to Dart Streams.
/// This provides several advantages:
///
///    - RxDart works with any API that expects a Dart Stream as an input.
///    - No need to implement or replace the many methods and properties from the core Stream API.
///    - Ability to create Streams with language-level syntax.
///
/// Overall, we attempt to follow the ReactiveX spec as closely as we can, but
/// prioritize fitting in with the Dart ecosystem when a trade-off must be made.
/// Therefore, there are some important differences to note between Dart's
/// [Stream] class and standard Rx `Observable`.
///
/// First, Cold Observables exist in Dart as normal Streams, but they are
/// single-subscription only. In other words, you can only listen a Stream
/// once, unless it is a hot (aka broadcast) Stream. If you attempt to listen to
/// a cold Stream twice, a StateError will be thrown. If you need to listen to a
/// stream multiple times, you can simply create a factory function that returns
/// a new instance of the stream.
///
/// Second, many methods contained within, such as `first` and `last` do not
/// return a `Single` nor an `Observable`, but rather must return a Dart Future.
/// Luckily, Dart's `Future` class is  conceptually similar to `Single`, and can
/// be easily converted back to a Stream using the `myFuture.asStream()` method
/// if needed.
///
/// Third, Streams in Dart do not close by default when an error occurs. In Rx,
/// an Error causes the Observable to terminate unless it is intercepted by
/// an operator. Dart has mechanisms for creating streams that close when an
/// error occurs, but the majority of Streams do not exhibit this behavior.
///
/// Fourth, Dart streams are asynchronous by default, whereas Observables are
/// synchronous by default, unless you schedule work on a different Scheduler.
/// You can create synchronous Streams with Dart, but please be aware the the
/// default is simply different.
///
/// Finally, when using Dart Broadcast Streams (similar to Hot Observables),
/// please know that `onListen` will only be called the first time the
/// broadcast stream is listened to.
abstract class Rx {
  /// The defer factory waits until an observer subscribes to it, and then it
  /// creates a [Stream] with the given factory function.
  ///
  /// In some circumstances, waiting until the last minute (that is, until
  /// subscription time) to generate the Stream can ensure that this
  /// Stream contains the freshest data.
  ///
  /// By default, DeferStreams are single-subscription. However, it's possible
  /// to make them reusable.
  ///
  /// ### Example
  ///
  ///     Rx.defer(() => Stream.value(1))
  ///       .listen(print); //prints 1
  static Stream<T> defer<T>(Stream<T> Function() streamFactory, {bool reusable = false}) => DeferStream<T>(streamFactory, reusable: reusable);
}
