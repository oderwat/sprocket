import sprocket/internal/context

/// Context used by stateful components.
pub type Context =
  context.Context

/// Element that can be rendered
pub type Element =
  context.Element

/// A StatefulComponent is a component that has an associated state, lifecycle and takes props
pub type StatefulComponent(p) =
  context.StatefulComponent(p)

/// Create a new stateful component element from a given component function and props.
pub fn component(c: StatefulComponent(p), props: p) -> Element {
  context.component(c, props)
}

/// Render an element with the given context.
pub fn render(ctx: Context, element: Element) -> #(Context, Element) {
  #(ctx, element)
}
