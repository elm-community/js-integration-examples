# JavaScript Interop "Gray Patterns"

This document contains an assortment of common real-world JavaScript interop use-cases and corresponding approaches to solve them that may employ features in *unorthodox* ways in terms of referential transparency - hence the "Gray Patterns" moniker.
Both pros and cons are listed for every case, code samples may be supplied to demonstrate the overall approach although they're not considered production-ready snippets.

## Disclaimer

It is assumed that the reader is aware that there's always a trade-off in using *unorthodox* features, especially in conjunction with [Elm](https://elm-lang.org) as the main driver of an application.
[Here be dragons](https://en.wikipedia.org/wiki/Here_be_dragons).

## Table of Contents

* [Preventing Accidental Loss of Application State](#preventing-accidental-loss-of-application-state)

## Preventing Accidental Loss of Application State

If you ever find yourself in a situation where the user hasn't saved progress and want to prevent loss due to them closing the app the following approach using a simple [Custom Element](../webcomponents/) can be a simple albeit not overly reliable band-aid.

### Pros

  - Convenient drop-in usage without port setup

### Cons

  - This approach is "hiding" impure application behavior from your main application
  - The [HTML-spec on `onbeforeunload`](https://html.spec.whatwg.org/multipage/browsing-the-web.html#steps-to-fire-beforeunload) specifically regulates what counts as potentially "annoying, deceptive, or pointless", so the supplied message might not be shown at all

### Sample Custom Element

```javascript
/* global window, HTMLElement, customElements */

class PreventClose extends HTMLElement {
  connectedCallback() {
    if (window.location.host.includes("localhost")) {
      return;
    }
    this.beforeUnloadListener = (event) => {
      // Modern browsers will probably honor this `preventDefault`
      event.preventDefault();
      
      // This is legacy-browser behavior and not guaranteed to work
      // in modern browsers as it may be classified as intrusive
      return (event.returnValue =
        "Are you sure you want to exit? There are unsaved changes.");
    };
    window.addEventListener("beforeunload", this.beforeUnloadListener, {
      capture: true,
    });
  }
  disconnectedCallback() {
    window.removeEventListener("beforeunload", this.beforeUnloadListener, {
      capture: true,
    });
  }
}

customElements.define("prevent-close", PreventClose);
```

### Acknowledgements

Thanks to [@janwirth](https://github.com/janwirth) for the suggestion.
See [the corresponding discussion](https://github.com/elm-community/js-integration-examples/issues/9) for more detail.
