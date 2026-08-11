# clock

Clock abstraction — monotonic and wall-clock time for timestamps and timeouts.

## API

```mbt nocheck
///|
pub struct Clock {
  // monotonic clock for intervals
  // wall clock for timestamps
}

///|
pub fn Clock::new() -> Clock

///|
pub fn Clock::now(self : Clock) -> Timestamp

///|
pub fn Clock::elapsed_ms(self : Clock, from : Timestamp) -> Int
```

## Timestamp

```mbt nocheck
///|
pub type Timestamp @uuid.Uuid // opaque timestamp type

///|
pub fn Timestamp::to_string(self : Timestamp) -> String
pub fn Timestamp::to_unix_ms(self : Timestamp) -> Int64
```