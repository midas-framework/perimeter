import perimeter
import gleam/should

pub fn hello_world_test() {
  perimeter.hello_world()
  |> should.equal("Hello, from perimeter!")
}
