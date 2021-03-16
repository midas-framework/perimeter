# Perimeter

Gleam is a beautiful functional language, Perimeter helps interact with the outside world.

- Error Handling/Reporting
- Input Validation (Including email_address uuids)
- Telemetry/Observability (Comming Soon)
- Service wrappers

## Quickstart

API client that safely handles a call to an external service and parsing the response.

```rust
// my_app/api_client
import gleam/result
import perimeter/email_address.{EmailAddress}
import perimeter/services/http_client
import perimeter/input/http_response
import perimeter/input/json

pub type User{
  User(name: String, age: Option(Int), email: EmailAddress)
}

fn cast_user(raw) {
  try name = json.required(raw, "name", json.as_string)
  try age = json.optional(raw, "age", json.as_int)
  try email = json.required(raw, "email", json.as_email)
}

pub fn get_user(user_id) {
  try response = http_client.send(request)
  |> result.map_error(http_client.to_report)
  
  try raw = http_response.get_json(response)

  try user = cast_user(raw) 
  |> result.map_error(input.to_server_report)

  Ok(user)
}
```

Server module that handles external input, calls the API server and returns a consistent report for all errors.

```rust
import gleam/result
import perimeter/input/http_request
import perimeter/input/http_query
import perimeter/scrub
import my_app/api_client

pub fn params(raw) {
  http_query.required(raw, "user_id", http_query.as_uuid)
}

fn do_handle(request) {
  try raw = http_request.get_query(rquest)

  try user_id = params(raw)
  |> result.map_error(input.to_report)
  
  try user = api_client.get_user(user_id)
  Ok(response_from_user(user))
}

pub fn handle(request) {
  case do_handle(request) {
    Ok(response) -> reponse
    Error(report) -> scrub.to_response(report)
  }
}
```


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

> Can I take the username 'Bob'?
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
pub type Kind {
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