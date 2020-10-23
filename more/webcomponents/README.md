# A Guide to Using Elm With Webcomponents

This document is meant to be a practical guide to the somewhat confusing [web components specs][wc-specs].

Most documentation on web components show the spec and basic usage examples, assuming that you already know the intricate details of why specific parts of the spec exist in the first place and what use case they try to solve. This situation can be daunting even for experienced web developers and even more so for newcomers.

We try to be as concise as possible, while also providing enough information to get you up and running.

## TL;DR
If you are looking for a quick start with Elm, Webcomponents and the setup of choice have a look at
* [web components setup](#web-components-setup)
* [the browser support section](#Browser-Support)
* don't forget to check [the gotchas section](#Gotchas) to learn how to build Webcomponents that play nice with Elm.

## Prerequisites

First-off: if you haven't read [the official Elm guide][guide] you should do so before reading on, of particular note is [the interop section][guide-interop] as this is where the usage of [ports][guide-ports] and [custom elements][guide-custom-elements] is motivated.

Now that you're up to date and positive that using web components is the way to solve the problem at hand we'll start off with a quick summary of what web components are, followed by a rundown of the parts of [the spec][wc-specs] you'll most likely interact with when using Elm.

The remainder of the guide is dedicated to getting your app ready for web components in all the browsers you want/need to support.

## What are web components and what can I do with them?

You might have heard or read "just use web components" as an answer to the question how to integrate a particular JavaScript API or external library with Elm. 

To quote the first paragraph on the [web components specs page][wc-specs]

> These four specifications can __be used on their own__ but combined allow developers to define their own tags (custom element), whose styles are encapsulated and isolated (shadow dom), that can be restamped many times (template), and have a consistent way of being integrated into applications (es module).

I've emphasized the most important information: in order to "use web components" you can and should actually pick and choose what part of the spec you need in order to solve your problem.

* You don't need to use Shadow DOM, if you don't need style encapsulation.
* You don't need to use HTML templates, if you already have a templating solution.
* You don't need ES Modules, if you have a compile-to-js language like, say, *drumroll* Elm.

You may find yourself using all of these specs but they aren't usually necessary in conjuction with Elm. If you want to dive deeper into Webcomponents in plain JavaScript the [MDN page about Webcomponents][mdn-wc] is a good place to start.


## Web Components Setup

At the time of writing this article you're probably using some form of build system for your JavaScript assets, by choice, custom or force. A detailed assessment of bundling modern web apps is outside the scope of this guide but you can check out [our minimal ES5 compatible setup](minimal-es5-setup.html) that provides the polyfills necessary to use web components with older browsers like Internet Explorer 11.

There is more information available in the [browser support section](#browser-support).


## Custom Elements And Elm

Note that if at this point you skipped the earlier requests to have a look at the [interop section of the Elm guide][guide-interop] it's a good idea to do so now. 

So we've looked at [the specs][wc-specs] and the most relevant one to Elm is arguably [Custom Elements][wc-custom-elements]. Looking at the examples on that page, defining a custom element is easy enough.

```javascript
class MyElement extends HTMLElement {}
customElements.define("my-element", MyElement);
```

This defines a new HTML element `<my-element>`. Note that
* the name *has* to include a hyphen and
* the class *needs* to extend `HTMLElement`.

This is what custom elements are about: they let you build your own HTML elements with behavior tailored to your application that are indistinguishable from built-in elements like `<input>` or `<section>`. Which in turn means we can create these kind of elements within Elm without problems.

```elm
import Html

element =
    Html.node "my-element" [] [ Html.text "Awesome!" ]
```

Let's have a look at the anatomy of a custom element. Note that this only covers the part of the API that is most relevant to Elm, we provide links to associated concepts where appropriate.

### Construction ([demo](https://ellie-app.com/8Vw6BbYYpc4a1))

A custom element, just like any other built-in element, can be created declaratively using HTML or imperatively using JavaScript.

```javascript
customElements.define("my-element", class extends HTMLElement {});

const element = document.createElement("my-element");
```
```html
<!-- Note that custom elements can not be self-closing -->
<my-element></my-element>
```
```elm
import Html

myElement =
    Html.node "my-element" [] []
```

### Lifecycles ([demo](https://ellie-app.com/8Vw7J3nFNNma1))

There are lifecycles you can attach clunkily-named callbacks to.

```javascript
customElements.define("i-support-lifecycles", class extends HTMLElement {
    constructor() {
        super();
        // This <i-support-lifecycles> is being initialized, it's not been
        // added to any document yet but you can initialize your fields but
        // don't temper with the DOM just yet, do that in `connectedCallback`
    }
    adoptedCallback() {
        // This <i-support-lifecycles> has been moved to a different document
    }
    connectedCallback() {
        // This <i-support-lifecycles> has been added to the DOM
    }
    disconnectedCallback() {
        // This <i-support-lifecycles> has been removed from the DOM
    }
});
```

### Attributes ([demo](https://ellie-app.com/8Vwfz6c5v2wa1))

Custom elements may declare supported attributes via `observedAttributes` - only attribute names returned from this trigger the `attributeChangedCallback` when changed. Note that attributes can only carry `string` values.

There's also a [discussion on whether to use an attribute or a property](#attributes-vs-properties), if you're not sure which to use.

```javascript
customElements.define("twbs-alert", class extends HTMLElement {
    static get observedAttributes() {
        // We need to declare which attributes should be observed,
        // only these trigger the `attributeChangedCallback`
        return ['type'];
    }
    connectedCallback() {
        this.classList.add('alert');
    }
    attributeChangedCallback(name, oldValue, newValue) {
        switch (name) {
            case 'type':
                this.classList.remove(`alert-${oldValue}`);
                this.classList.add(`alert-${newValue}`);
                break;
        }
    }
});

const element = document.createElement("twbs-alert");
element.setAttribute("type", "info");
```
```html
<twbs-alert type="info"></twbs-alert>
```
```elm
import Html
import Html.Attributes

alert =
    Html.node "twbs-alert"
        [ Html.Attributes.attribute "type" "info"
        -- or alternatively Html.Attributes.type_ "info"
        ]
        [ Html.text "This is a Twitter Bootstrap info box"
        ]
```

If you need to transfer object data you can use a [property](#Properties).

### Properties ([demo](https://ellie-app.com/8VwjNrnhyKKa1))

Custom elements can declare properties via `get` and `set`, most kinds of JavaScript objects are supported.

There's also a [discussion on whether to use an attribute or a property](#attributes-vs-properties), if you're not sure which to use.

```javascript
customElements.define("atla-trivia", class extends HTMLElement {
    constructor() {
        super();
        this._meta = null;
    }
    set meta(value) {
        this._meta = value;
    }
    get meta() {
        return this._meta;
    }
});

const element = document.createElement("atla-trivia");
element.meta = {
    teamAvatar: ["Aang", "Katara", "Soka"],
    seasons: 3,
};
```
```html
<!-- You can't set properties directly in raw HTML, sorry -->
```

With Elm you need to use a JSON encoder provided by the [`elm/json`][elmpkg-elm-json] package.

```elm
import Html
import Html.Attributes
import Json.Encode -- elm install elm/json

trivia =
    Html.node "atla-trivia"
        [ Html.Attributes.property "meta"
            (Json.Encode.object
                [ ( "teamAvatar"
                  , Json.Encode.list Json.Encode.string
                    [ "Aang"
                    , "Katara"
                    , "Soka"
                    ]
                  )
                , ( "seasons", Json.Encode.int 3 )
                ]
            )
        ]
        []
```

### Attributes vs Properties
For Elm projects a good rule of thumb is

> Use properties unless you want your custom elements to be used from hand-written or server-rendered HTML.

The reasoning is
* You're interacting with your custom element via JavaScript anyways, so the fact that properties can not be set from raw HTML is usually not an issue
* You can transfer structured data via properties, not just strings
* It's easier to use a consistent interaction method with custom elements from Elm - just use `Html.Attributes.property` everywhere

On the other hand writing custom elements with attributes only might be more suitable for your use case as they can easily be included in static HTML, hand-written or produced by server-side-rendering.


### Children ([demo](https://ellie-app.com/8VwmHKFMYCqa1))
As we've noted a number of times: custom elements are just like regular HTML elements, this includes the ability to be a root node for a sub-tree, your custom element can have child nodes.

```javascript
customElements.define("tree-root", class extends HTMLElement {});

const root = document.createElement("tree-root");
const span = document.createElement("span");
span.innerText = "A span";
const div = document.createElement("div");
div.innerText = "A div";
const plainText = document.createTextNode("Plain text");

root.appendChild(span);
root.appendChild(div);
root.appendChild(plainText);
```
```html
<tree-root>
    <span>A span</span>
    <div>A div</div>
    Plain text
</tree-root>
```

This is equivalent to the following Elm code. Be sure to read up on [the gotchas](#Gotchas) due to Elm's virtual DOM, though.

```elm
import Html

subTree =
    Html.node "tree-root" []
        [ Html.span [] [ Html.text "A span" ]
        , Html.div [] [ Html.text "A div" ]
        , Html.text "Plain Text"
        ]
```

### Listening to Events ([demo](https://ellie-app.com/8Vwpg8T5GDQa1))
Custom elements support listening to events; this is usually not that useful in conjunction with Elm since you can't imperatively trigger events with it. However, it allows you to employ some nifty tricks like [event delegation][jq-event-delegation] where you use the [DOM's event bubbling phase][mdn-event-bubbling] to listen for events that "bubble up" from your custom element's children.

```javascript
customElements.define("event-delegator", class extends HTMLElement {
    _handleInnerClick(evt) {
        evt.preventDefault();
        evt.stopPropagation();
        alert(`You clicked inside of me`);
    }
    connectedCallback() {
        this.addEventListener("click", this._handleInnerClick)
    }
    disconnectedCallback() {
        this.removeEventListener("click", this._handleInnerClick)
    }
});

const element = document.createElement("event-delegator");
const button = document.createElement("button");
button.innerHTML = "Click Me!";

element.appendChild(button);
document.body.appendChild(element);
```
```html
<event-delegator>
    <button>Click Me!</button>
</event-delegator>
```

As we've seen in [the Children section](#Children) building DOM trees with Elm is a breeze. In this example we see both the power and the potential problems with using custom elements in Elm, they allow you to execute arbitrary JavaScript inside your declarative views. So be aware of the fact that a rogue custom element can compromise Elm's runtime guarantees, have a look at [the Gotchas section](#Gotchas) to learn more.

```elm
import Html

root =
    Html.node "event-delegator" []
        [ Html.button [ {- no `onClick` here -} ]
            [ Html.text "Click Me!"
            ]
        ]
```


### Triggering Events ([demo](https://ellie-app.com/8VvL6ggT5qJa1))

Custom elements [can listen to events](#Listening-to-Events) but they become really useful as soon as they're triggering events themselves. You mainly want to use this as an adapter to give Elm access to [Web APIs][html5-apis] it does not yet support in form of a core package or to embed functionality from external JavaScript libraries.

To demonstrate this we build a slightly more involved custom element `<copy-to-clipboard>` that lets the user copy text from an Elm app via button click using the [Document.execCommand API][doc-exec-command]. This is a fairly old non-standard API that's widely supported, nonetheless. The [Clipboard API][mdn-clipboard] is the modern successor, in case you don't need support for older browsers.

The gist is that our element listens for `click` events from its children, copies the value of its `text` attribute to the clipboard and triggers a [`CustomEvent`][mdn-customevent] notifying Elm that the operation has been successful, Elm can also decode event data being passed.

```javascript
customElements.define("copy-to-clipboard", class extends HTMLElement {
    static get observedAttributes() {
        return ["text"];
    }
    _handleClick(evt) {
        evt.preventDefault();
        evt.stopPropagation();
        const text = this.getAttribute("text");
        this._copy(text);
        this.dispatchEvent(new CustomEvent("clipboard", {
            bubbles: true,
            cancelable: true,
            detail: {
                copiedText: text,
            },
        }));
    }
    _copy(value) {
        const preSelected =            
            document.getSelection().rangeCount > 0
                ? document.getSelection().getRangeAt(0)
                : false;

        const textarea = document.createElement('textarea');
        textarea.setAttribute('readonly', '');
        textarea.style.position = 'absolute';
        textarea.style.left = '-9999px';
        textarea.value = value;
        document.body.appendChild(textarea);
      
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        if (preSelected) {
            document.getSelection().removeAllRanges();
            document.getSelection().addRange(preSelected);
        }
    }
    connectedCallback() {
        this.addEventListener("click", this._handleClick);
    }
    disconnectedCallback() {
        this.removeEventListener("click", this._handleClick);
    }
});
```
```elm
module Main exposing (main)

import Browser
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode exposing (Decoder)


type Msg
    = CopiedToClipboard String


type alias Model =
    { copied : Maybe String
    }


clipboardEventDecoder : (String -> msg) -> Decoder msg
clipboardEventDecoder toMsg =
    Json.Decode.map (\copiedTextFromDetail -> toMsg copiedTextFromDetail)
        (Json.Decode.at [ "detail", "copiedText" ] Json.Decode.string)


view : Model -> Html Msg
view { copied } =
    let
        textToCopy =
            "Text from Elm"
    in
    Html.div []
        [ Html.node "copy-to-clipboard"
            [ Html.Attributes.attribute "text" textToCopy
            , Html.Events.on "clipboard" (clipboardEventDecoder CopiedToClipboard)
            ]
            [ Html.button []
                [ Html.text "Copy "
                , Html.text ("\"" ++ textToCopy ++ "\"")
                , Html.text " to clipboard"
                ]
            ]
        , case copied of
            Just _ ->
                Html.div []
                    [ Html.div [] [ Html.text "Copied!" ]
                    , Html.textarea
                        [ Html.Attributes.placeholder "Try pasting it in here"
                        ]
                        []
                    ]

            Nothing ->
                Html.text ""
        ]


update : Msg -> Model -> Model
update (CopiedToClipboard text) model =
    { model | copied = Just text }


main : Program () Model Msg
main =
    Browser.sandbox
        { init = { copied = Nothing }
        , update = update
        , view = view
        }

```

_Note that Internet Explorer needs [a polyfill for CustomEvent][mdn-customevent-polyfill]._

Many Elm apps use this technique to embed libraries like [CodeMirror](https://github.com/ellie-app/ellie/blob/a45637b81e2495ffada12f9a75dd6bb547a69226/assets/src/Ellie/Ui/CodeEditor.js) or [Google Maps](https://package.elm-lang.org/packages/PaackEng/elm-google-maps/latest/).

Until now all seems hunky-dory in the world of custom elements being embedded with Elm but there are some [gotchas](#Gotchas) you need to be aware of. We'll take a look at these in the next section.


## Gotchas

There are some things to keep in mind when employing custom elements in your Elm app.

### Web Components And Virtual DOM

Elm takes full control of the part of the DOM it manages. Like other virtual-dom based libraries it keeps track of the current state of the DOM in the form of an in-memory representation of the tree and assumes that what is currently rendered in the real DOM is a pure derivative from this in-memory representation.

Some libraries are more forgiving than others with unexpected mutations but if you mess with those nodes too much you risk breaking their invariants, which in turn will cause runtime exceptions, even in Elm. What that means in practice is that you should adhere to the following rules for your custom elements to play nice with virtual-dom libraries in general.

* 1) Make sure your custom element cleans up after itself via `disconnectedCallback` as Elm may decide to re-create any part of the DOM without notice.
* 2) This also means that you should not rely on Elm creating your custom element node exactly x amount of times.
* 3) If your custom element is supposed to receive child nodes from the outside like [in our little event delegation example](#Listening-to-Events) make sure not to add or remove any children as this may confuse Elm's virtual-dom.
* 4) If your custom element doesn't expect children from the outside you are free to manage the element's child nodes.
* 5) If you need both external and self-managed children you can "hide" them inside a [Shadow Root][mdn-shadow-dom], Elm won't inspect sub-trees of shadow roots. Note that there are polyfills for the Shadow DOM spec out there that work in older browsers but this API is farely involved so these might slow down the browser significantly and/or have unexpected behavior.

### Customized Built-ins

The [spec][wc-specs] mentions that you can [extend built-in elements][mdn-customized-builtins], e.g. to make your own `<button>`. [Elm's virtual dom does not support creating these kind of elements](https://github.com/elm/virtual-dom/issues/156). [This guide has a small example](#modern-environments-vs-the-spec) but note that this feature is not widely supported by browsers and it's probably best to avoid it altogether.


And while we're talking about gotchas...


## Browser Support

Looking at our basic example snippets you may have a very valid question. ([demo](https://ellie-app.com/8Vw6BbYYpc4a1))

```javascript
class MyElement extends HTMLElement {}
customElements.define("my-element", MyElement);
```

```elm
import Html

myElement =
    Html.node "my-element" [] [ Html.text "Awesome!" ]
```

> If that's all there is to it why do I even read this guide?

Glad you asked! As is usually the case, there's more than meets the eye.


### Older Environments

Our custom element seems to work... until we try to use our `<my-element>` component in Internet Explorer, some ancient mobile browser, a webview - `SyntaxError` or maybe `"customElements" is not defined`. Off to the "browser support" page; [looks very green and ready for showbiz][wc-home] but we remember [the word "polyfill"][wc-polyfills] so that is what catches our eye.

The gist is that not every browser supports web components out-of-the-box and some implementations are buggy so you need to include a sort-of base library. After we've included [the custom elements polyfill][wc-polyfill-custom-elements] our code agrees to run inside mobile browsers (and webviews?) but Internet Explorer is relentless, as always - `SyntaxError` is the bane of our existence.

It turns out that Internet Explorer doesn't support the `class` syntax introduced in ES6. Because we know that `class` syntax is actually just syntactic sugar for constructor functions and prototype chaining we begrudgingly rewrite our example component.

```javascript
function MyElement() {}
MyElement.prototype = Object.create(HTMLElement.prototype);
customElements.define("my-element", MyElement);
```

Internet Explorer still complains `the custom element constructor did not produce the element being upgraded`, odd. After more research we [come across the magic incantation][so-custom-elements] that makes our component appear in all browsers. Note that the polyfill detects modern browsers automatically now so we at least don't need to [patch the native implementation manually to work with ES5 style classes][wc-polyfill-custom-elements-es5].

This means that per spec native custom element implementations only work with ES6 classes, keep that in mind!

```html
<!-- We also need a polyfill for `Reflect` -->
<script src="https://unpkg.com/es6-shim@0.35.5/es6-shim.min.js"></script>
<script src="https://unpkg.com/@webcomponents/custom-elements"></script>
```

```javascript
function MyElement() {
    return Reflect.construct(HTMLElement, [], this.constructor);
}
MyElement.prototype = Object.create(HTMLElement.prototype);
MyElement.prototype.constructor = MyElement;
MyElement.prototype.connectedCallback = function () {
    this.appendChild(document.createTextNode("Water!"));
};
Object.setPrototypeOf(MyElement, HTMLElement);

customElements.define("my-element", MyElement);
```

Have a look at the [minimal example setup that works in ECMAScript 5 compliant browsers](minimal-es5-setup.html).

For cross-browser support you'll need a polyfill for old browsers *and* modern browsers! 

And that's not even the whole story. There are other approaches like serving different bundles to different browsers like [Angular 8+ differential loading][ng-differential-loading] does. Which also has problems, having two different code base versions of your app run in older and newer browsers respectively can lead to bugs that are very hard track down.

[ng-differential-loading]: https://blog.angular.io/version-8-of-angular-smaller-bundles-cli-apis-and-alignment-with-the-ecosystem-af0261112a27 
[so-custom-elements]: https://stackoverflow.com/questions/50295703/create-custom-elements-v1-in-es5-not-es6 


### Modern Environments vs the Spec

You may think that targeting only modern browsers frees you from all the hassle. Let's take a look at [the other example][wc-custom-elements] on the web components page.

```javascript
class CustomizedButton extends HTMLButtonElement {
    connectedCallback() {
        this.style.backgroundColor = "orange";
    }
}
customElements.define("customized-button", CustomizedButton, { extends: "button" });
```
```html
<button is="customized-button">Customized!</button>
```

If we open this in Chrome our button is indeed a button with an orange background. Safari does not concur, neither does pre-Chromium Microsoft Edge nor [any Webkit based browser possibly forever][webkit-nope] which includes the iOS browser. `Customized built-in` s as they're called are part of the spec but a non-significant amount of browsers doesn't and probably won't support them anytime soon.

Although there is [a polyfill][customized-polyfill] it's probably best to ignore that part of the spec, it's not safe to use as [is documented in this w3c issue][w3c-nope] and layering polyfills upon polyfills onto each other might have consequences.

Also note that Elm's virtual-dom does not support creating these customized built-ins, see the [gotchas section](#gotchas) for more information.

[customized-polyfill]: https://github.com/ungap/custom-elements-builtin 
[webkit-nope]: https://bugs.webkit.org/show_bug.cgi?id=182671 
[w3c-nope]: https://github.com/w3c/webcomponents/issues/509 


## Conclusion

In this guide we've discussed the impetus of why webcomponents exist in the first place and what parts of the spec are particularly relevant when working with Elm.

We've investigated a number usecases with demos where custom elements come in handy to enhance Elm's vocabulary in terms of not yet natively supported web APIs and interop scenarios with external JavaScript libraries.

I hope you now have a fair grasp on these topics so you can confidently incorporate custom elements in your Elm workflow when needed.


## Further Reading

* [Mozilla Developer Network Article on Webcomponents][mdn-wc]
* [https://webcomponents.org][wc-home]
* [Alex Korban's A Straight Forwared Introduction to Custom Elements](https://korban.net/posts/elm/2018-09-17-introduction-custom-elements-shadow-dom/)
* [All the Ways To Make a Web Component](https://webcomponents.dev/blog/all-the-ways-to-make-a-web-component/)


[doc-exec-command]: https://developer.mozilla.org/en-US/docs/Web/API/Document/execCommand 
[elmpkg-elm-json]: https://package.elm-lang.org/packages/elm/json/latest
[jq-event-delegation]: https://learn.jquery.com/events/event-delegation/ 
[guide]: https://guide.elm-lang.org
[guide-interop]: https://guide.elm-lang.org/interop/
[guide-ports]: https://guide.elm-lang.org/interop/ports.html 
[guide-custom-elements]:https://guide.elm-lang.org/interop/custom_elements.html 
[html5-apis]: https://developer.mozilla.org/en-US/docs/Web/API 
[mdn-clipboard]: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard_API 
[mdn-customevent]: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent
[mdn-customevent-polyfill]: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent#Polyfill
[mdn-customized-builtins]:https://developer.mozilla.org/en-US/docs/Web/Web_Components/Using_custom_elements#Customized_built-in_elements
[mdn-event-bubbling]: https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Building_blocks/Events#Event_bubbling_and_capture 
[mdn-shadow-dom]: https://developer.mozilla.org/en-US/docs/Web/Web_Components/Using_shadow_DOM
[mdn-slot]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/slot 
[mdn-wc]: https://developer.mozilla.org/en-US/docs/Web/Web_Components 
[w3c]: https://www.w3.org/ 
[wc-custom-elements]:https://www.webcomponents.org/specs#the-custom-elements-specification 
[wc-home]: https://www.webcomponents.org/
[wc-polyfills]: https://www.webcomponents.org/polyfills 
[wc-polyfill-custom-elements]: https://github.com/webcomponents/polyfills/tree/master/packages/custom-elements
[wc-polyfill-custom-elements-es5]: https://github.com/webcomponents/polyfills/tree/master/packages/custom-elements#es5-vs-es2015 
[wc-specs]: https://www.webcomponents.org/specs
