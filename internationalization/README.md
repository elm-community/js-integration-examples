# Internationalization

This is a minimal example of how to use the `Intl` library with a custom element.

![Demo](demo.gif)

The important code lives in `src/Main.elm` and in `index.html` with comments!


## Building Locally

Run the following commands:

```bash
git clone https://github.com/elm-community/js-integration-examples.git
cd js-integration-examples/websockets

elm make src/Main.elm --output=elm.js
open index.html
```

Some terminals may not have an `open` command, in which case you should open the index.html file in your browser another way.
