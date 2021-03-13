# Perimeter

Gleam is a beautiful functional language, Perimeter helps interact with the outside world.

- Error Handling/Reporting
- Input Validation
- Telemetry/Observability (Comming Soon)
- Service wrappers

```rust
import perimeter/input/http_request

pub fn handle(request) {
    try raw = input.request_json(request)
    try raw = input.request_query()
    // these are a mess because integers would be strings here.
    try raw = input.request_form()
    try user_id = json.required(raw, "user", as_uuid)
    |> result.map_error(json.to_report)
}
```


Have span context as the current span before it is closed,
wire up sentry

## Assumptions

When starting with Gleam you might quickly realise that talking to the outside world is the hardest part.
Perimeter aims to make it easier to write a robust shell that surrounds the functional core of your program logic. 

Several assumptions are made about how best to do things.

### There exists a useful global error type.

I assert there exists a type that can more usefully represent an error than a simple string, 
that encompases all possible error types.

This doesn't mean there might be an even better error type specific to your domain if you have the time to design it.
Just that we can provide one that is "good enough" for the early days of a project.

### Error is a really bad name

Error is a really bad name for why a program didn't give you the output you asked for.

> Can I take username Bob?
>
> ERROR, unfortunetly that name is already taken.

I would argue that if the username Bob is already taken there is no error in this program.

Instead all terminating programs either return output or are scrubbed.

> scrub: cancel or abandon (something).

### Simple view of computation

In pure functions, computation relies only on input and the logic that is executed.

```
input -> logic -> output
```

In general computation, which we call programs/api calls/cli computation we instead have the following.

```
input + state -> logic + services -> output
```

Any scrub, must be the result of a problem in input, state, logic or one of those three in a depended on service.

This division is how we classify scrubs (errors)

```rust
pub type Scrub {
  // No output because of problem with arguments/request/caller   
  RejectedInput

  // No output due to limitation with current state, not knowable to caller.  
  // Includes expired, gone, conflict.
  Unprocessable

  // When the programmer has made a mistake
  LogicError

  // When it's not possible to use a service
  // Includes API requests, File/OS system calls
  ServiceUnreachable

  // A service was unable to provide an answer due to problem with it's own logic or services
  ServiceError

  // Error's from systems not following this convention that might represent scrubs of more than one kind. 
  Unknown
}
```

### Chained scrubs

A call is made to service A which in turn makes a call to service B.

If B returns early because of rejected input. 
A should return early due to a Logic Error, because it is assumed that it should validate it's own input before calling downstream.

scrubs flow upstream as follows

- RejectedInput -> LogicError
- Unprocessable -> Unprocessable
- LogicError -> ServiceError
- ServiceUnavailable -> ServiceUnavailable
- ServiceError -> ServiceError




### Appendix: Other names

Perimeter could otherwise be called Shell, from "functional core imperitive shell", but that has to many other meanings in programming.

Scrub could otherwise be abort or an apology. I considered cancelled but that seamed user initiated

### Appendix: What is an error

Error any old excuse about why something didn't happen even if it was the correct behaviour of a well functioning system