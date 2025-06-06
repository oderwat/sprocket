import gleam/dict
import gleam/int
import gleam/option.{None, Some}
import gleam/string
import sprocket.{component, render}
import sprocket/hooks.{state}
import sprocket/html/attributes.{id, input_type, name, value}
import sprocket/html/elements.{button, div, form, fragment, input, text}
import sprocket/html/events
import sprocket/internal/context.{type Context}
import sprocket/test_helpers.{
  BlurEvent, ById, ClickEvent, FocusEvent, FormChangeEvent, FormSubmitEvent,
  InputEvent, assert_regex, connect, find_element, key_down, mouse_move,
  render_event, render_html,
}

fn button_component(ctx: Context, _props) {
  use ctx, count, set_count <- state(ctx, 0)

  // Define event handlers
  let increment = fn(_) { set_count(count + 1) }
  let reset = fn(_) { set_count(0) }

  let current_count = int.to_string(count)

  render(
    ctx,
    fragment([
      text("current count is: " <> current_count),
      button([id("increment"), events.on_click(increment)], [text("increment")]),
      button([id("reset"), events.on_click(reset)], [text("reset")]),
    ]),
  )
}

pub fn button_events_test() {
  let view = component(button_component, Nil)

  let spkt = connect(view)

  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 0")

  // click increment button
  let spkt = render_event(spkt, ClickEvent, "increment")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 1")

  let spkt = render_event(spkt, ClickEvent, "increment")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 2")

  // click reset button
  let spkt = render_event(spkt, ClickEvent, "reset")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 0")
}

fn input_component(ctx: Context, _props) {
  use ctx, name, set_name <- state(ctx, "bob")

  // Define event handlers
  let process_input = fn(e) {
    case events.decode_target_value(e) {
      Ok(value) -> set_name(value)
      Error(_) -> Nil
    }
  }

  render(
    ctx,
    fragment([
      input([
        id("name_input"),
        input_type("text"),
        events.on_input(process_input),
        value(name),
      ]),
    ]),
  )
}

pub fn input_events_test() {
  let view = component(input_component, Nil)

  let spkt = connect(view)

  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with(
      "<input id=\"name_input\" type=\"text\" value=\"bob\"></input>",
    )

  let spkt = render_event(spkt, InputEvent("a"), "name_input")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with(
      "<input id=\"name_input\" type=\"text\" value=\"a\"></input>",
    )

  let spkt = render_event(spkt, InputEvent("al"), "name_input")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with(
      "<input id=\"name_input\" type=\"text\" value=\"al\"></input>",
    )

  let spkt = render_event(spkt, InputEvent("alice"), "name_input")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with(
      "<input id=\"name_input\" type=\"text\" value=\"alice\"></input>",
    )
}

fn mouse_component(ctx: Context, _props) {
  use ctx, position, set_position <- state(ctx, #(0, 0))

  // Define event handlers
  let process_mousemove = fn(e) {
    case events.decode_mouse_event(e) {
      Ok(events.MouseEvent(x:, y:, ..)) -> set_position(#(x, y))
      Error(_) -> Nil
    }
  }

  render(
    ctx,
    fragment([
      text(
        "Mouse position is x: "
        <> int.to_string(position.0)
        <> " y: "
        <> int.to_string(position.1),
      ),
      div([id("mouse_input"), events.on_mousemove(process_mousemove)], []),
    ]),
  )
}

pub fn mouse_events_test() {
  let view = component(mouse_component, Nil)

  let spkt = connect(view)

  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("Mouse position is x: 0 y: 0")

  let spkt = render_event(spkt, mouse_move(123, 456), "mouse_input")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("Mouse position is x: 123 y: 456")

  let spkt = render_event(spkt, mouse_move(-23, 1024), "mouse_input")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("Mouse position is x: -23 y: 1024")
}

pub fn form_component(ctx: Context, _props) {
  use ctx, submitted, set_submitted <- state(ctx, None)
  use ctx, validation_error, set_validation_error <- state(ctx, None)

  let submit_form = fn(e) {
    case events.decode_form_data(e) {
      Ok(data) -> {
        case dict.get(data, "name") {
          Ok(name) -> set_submitted(Some(name))
          Error(_) -> Nil
        }
      }
      Error(_) -> Nil
    }
  }

  let validate_form = fn(e) {
    case events.decode_form_data(e) {
      Ok(data) -> {
        case dict.get(data, "name") {
          Ok("") -> set_validation_error(Some("Name cannot be empty"))
          _ -> set_validation_error(None)
        }
      }
      Error(_) -> Nil
    }
  }

  render(
    ctx,
    fragment([
      div([id("prompt")], case submitted {
        Some(submitted) -> [text("Hello, " <> submitted <> "!")]
        None -> [text("Please enter your name")]
      }),
      case validation_error {
        Some(error) -> div([id("validation-error")], [text(error)])
        None -> fragment([])
      },
      form(
        [
          id("test_form"),
          events.on_submit(submit_form),
          events.on_change(validate_form),
        ],
        [
          input([input_type("text"), name("name")]),
          button([], [text("Submit")]),
        ],
      ),
    ]),
  )
}

pub fn form_component_test() {
  let view = component(form_component, Nil)

  let spkt = connect(view)

  let #(spkt, _rendered) = render_html(spkt)

  let assert True =
    spkt
    |> find_element(ById("prompt"))
    |> assert_regex("Please enter your name")

  let spkt =
    render_event(
      spkt,
      FormChangeEvent(dict.from_list([#("name", "")])),
      "test_form",
    )

  let assert True =
    spkt
    |> find_element(ById("validation-error"))
    |> assert_regex("Name cannot be empty")

  let spkt =
    render_event(
      spkt,
      FormSubmitEvent(dict.from_list([#("name", "alice")])),
      "test_form",
    )

  let assert True =
    spkt
    |> find_element(ById("prompt"))
    |> assert_regex("Hello, alice!")

  let spkt =
    render_event(
      spkt,
      FormSubmitEvent(dict.from_list([#("name", "bob")])),
      "test_form",
    )

  let assert True =
    spkt
    |> find_element(ById("prompt"))
    |> assert_regex("Hello, bob!")
}

type FocusState {
  Blurred
  Focused
  NoFocus
}

fn blur_focus_component(ctx: Context, _props) {
  use ctx, focus, set_focus <- state(ctx, NoFocus)

  let set_blurred = fn(_) { set_focus(Blurred) }
  let set_focused = fn(_) { set_focus(Focused) }

  render(
    ctx,
    fragment([
      case focus {
        Blurred -> text("blurred")
        Focused -> text("focused")
        NoFocus -> text("not focused")
      },
      input([
        id("input"),
        events.on_blur(set_blurred),
        events.on_focus(set_focused),
      ]),
    ]),
  )
}

pub fn blur_focus_test() {
  let view = component(blur_focus_component, Nil)

  let spkt = connect(view)

  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("not focused")

  let spkt = render_event(spkt, FocusEvent, "input")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("focused")

  let spkt = render_event(spkt, BlurEvent, "input")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("blurred")
}

fn keypress_component(ctx: Context, _props) {
  use ctx, key, set_key <- state(ctx, None)

  let process_keypress = fn(e) {
    case events.decode_keypress(e) {
      Ok(key) -> set_key(Some(key))
      Error(_) -> Nil
    }
  }

  render(
    ctx,
    fragment([
      case key {
        Some(key) -> text("Key pressed: " <> key)
        None -> text("No key pressed yet")
      },
      input([id("input"), events.on_keydown(process_keypress)]),
    ]),
  )
}

pub fn keypress_test() {
  let view = component(keypress_component, Nil)

  let spkt = connect(view)

  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("No key pressed yet")

  let spkt = render_event(spkt, key_down("a", "KeyA"), "input")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("Key pressed: a")

  let spkt = render_event(spkt, key_down("b", "KeyB"), "input")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("Key pressed: b")

  let spkt = render_event(spkt, key_down("Enter", "Enter"), "input")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("Key pressed: Enter")
}
