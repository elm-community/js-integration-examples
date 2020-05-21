# A Guide to Using Elm With Webcomponents

This document is meant to be a practical usage guide to [the various web components specs][wc-specs] with the goal to provide you with the necessary tools to interop with web APIs that are not yet covered by Elm's core packages. The reason this guide exists is that most tutorials and documentation on web components just dump all the specs and some basic usage examples on you assuming that you already know the intricate details of why specific parts of the spec exist in the first place and what use case they try to solve. This situation can be daunting even for experienced web developers and even more so for newcomers. We aim to be as concise as possible while also providing sufficient information to get you up and running in no time.

## TL;DR
If you are looking for a quick start with Elm, Webcomponents and the setup of choice have a look at [the browser support section](#Browser-Support), [the bundling section](#Bundling) where we have collected most of the setups people tend to use for their apps and don't forget to check [the Gotchas section](#Gotchas) so you know how to build Webcomponents that play nice with Elm.

## Prerequisites

First-off: if you haven't read [the official Elm guide][guide] you should do so before reading on, of particular note is [the interop section][guide-interop] as this is where the usage of [ports][guide-ports] and [custom elements][guide-custom-elements] is motivated.

Now that you're up to date and positive that using web components is the way to solve the problem at your hands we'll start off with a quick summary of what people mean when they say "just use web components" followed by a rundown of the parts of [the spec][wc-specs] you'll most likely interact with when using Elm. The remainder of the guide is dedicated to getting your app ready for web components in all the browsers you want/need to support.

## What are web components and what can I do with them?

You might have heard or read "just use web components" as an answer to the question how to integrate a particular JavaScript API or external library with Elm. If you've been around the web platform and its eco system you may already know exactly what to do; if you had to make use of your favorite search engine and found yourself puzzled over what the heck a "Shadow DOM" is supposed to be and whether it is safe for work to dive deeper into that web search this section is for you.

To quote the first paragraph on the [web components specs page][wc-specs]

> These four specifications can be used on their own but combined allow developers to define their own tags (custom element), whose styles are encapsulated and isolated (shadow dom), that can be restamped many times (template), and have a consistent way of being integrated into applications (es module).

This paragraph provides an elegant summary of what the web components specs have to offer but as a newcomer you may miss the most vital piece of information about web components. Instead of telling you outright what I mean let's instead have a little discussion on what the actual purpose of web components is in the first place.

There's no need to bore you with all the historical details on the conception of JavaScript and its turbulent lifetime so far, the web is full of these, suffice to say "the browser" as an application delivery platform is a messy environment with all sorts of short-comings and inconsistencies across vendors. Many of these problems have been tackled with library-specific APIs, resulting in a lot of unnecessary library and/or framework lock-in and a gazillion incompatible ways to do the same thing. Good examples are the various module and package systems - like [CommonJS][module-commonjs], [AMD][module-amd], [Meteor packages][module-meteor] - and the fact that basically every library created before ES6/ES2015 has its own way to imitate class based inheritance on top of JavaScript's prototype model - [Backbone has one][oop-backbone], [base2 has one][oop-base2], [dojo had one][oop-dojo], [Ember has one][oop-ember], [ExtJS has one][oop-extjs], [YUI has one][oop-yui], you get the idea.

This wild west not-invented-here mentality eventually lead to the standardization and introduction of ES6 classes and the ES6 module system with the goal to provide common solutions to common problems in an interoperable way. The web components spec consists of a set of specifications aimed to address other frequently encountered issues many libraries and frameworks provide mutually incompatible APIs for, building on top of what had been introduced in ES6.

To again quote the first paragraph on the [web components specs page][wc-specs]

> These four specifications __can be used on their own__ but combined allow developers to define their own tags (custom element), whose styles are encapsulated and isolated (shadow dom), that can be restamped many times (template), and have a consistent way of being integrated into applications (es module).

I've emphasized the most important information: in order to "use web components" you can and should actually pick and choose what part of the spec you need in order to solve your problem. You don't need to use Shadow DOM, if you don't need style encapsulation. You don't need to use HTML templates, if you already have a templating solution. You don't need ES Modules, if you have a compile-to-js language like, say, *drumroll* Elm. You may find yourself using all of these specs but they aren't usually necessary in conjuction with Elm.

If you want to dive deeper into Webcomponents in plain JavaScript the [MDN page about Webcomponents][mdn-wc] is a good place to start.


## Custom Elements And Elm

Note that if at this point you skipped the earlier requests to have a look at the [interop section of the Elm guide][guide-interop] I'll try to nudge you again to do so... you may feel nudged now. 

So we've looked at [the specs][wc-specs] and the one we've been dancing around so far is actually the spec that's most relevant to Elm: [Custom Elements][wc-custom-elements]. Looking at the examples on that page, defining a custom element is easy enough.

```javascript
class MyElement extends HTMLElement {}
customElements.define("my-element", MyElement);
```

This unsurprisingly defines a new HTML element `<my-element>`. Note that the name *has* to include a hyphen and the class *needs* to extend `HTMLElement`. This is what custom elements are about: they let you build your own HTML elements with behavior tailored to your application that are indistinguishable from built-in elements like `<input>` or `<section>`. Which in turn means we can create these kind of elements within Elm without problems, we've probably done it many times before.

```elm
import Html

element =
    Html.node "my-element" [] [ Html.text "Awesome!" ]
```

Let's have a look at the anatomy of a custom element. Note that this only covers the part of the API that is most relevant to Elm, we provide links to associated concepts where appropriate.

### Construction

A custom element, just like any other built-in element, can be created declaratively using HTML or imperatively using JavaScript. ([demo](https://ellie-app.com/8Vw6BbYYpc4a1))

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

btn =
    Html.node "my-element" [] []
```

### Lifecycles

There are lifecycles you can attach clunkily-named callbacks to. ([demo](https://ellie-app.com/8Vw7J3nFNNma1))

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

### Attributes

Custom elements may declare supported attributes via `observedAttributes` - only attribute names returned from this trigger the `attributeChangedCallback` when changed. Note that attributes can only carry `string` values. ([demo](https://ellie-app.com/8Vwfz6c5v2wa1))

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

element =
    Html.node "twbs-alert"
        [ Html.Attributes.attribute "type" "info"
        -- or alternatively Html.Attributes.type_ "info"
        ]
        [ Html.text "This is a Twitter Bootstrap info box"
        ]
```

If you need to transfer object data you can use a [property](#Properties).

### Properties

Custom elements can declare properties via `get` and `set`, most kinds of JavaScript objects are supported. ([demo](https://ellie-app.com/8VwjNrnhyKKa1))

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

element =
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

TODO
* [ ] Attrs vs Props

### Children
As we've noted a number of times: custom elements are just like regular HTML elements, this includes the ability to be a root node for a sub-tree, your custom element can have child nodes. ([demo](https://ellie-app.com/8VwmHKFMYCqa1))

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

### Listening to Events
Custom elements support listening to events; this is usually not that useful in conjunction with Elm since you can't imperatively trigger events with it. However, it allows you to employ some nifty tricks like [event delegation][jq-event-delegation] where you use the [DOM's event bubbling phase][mdn-event-bubbling] to listen for events that "bubble up" from your custom element's children. ([demo](https://ellie-app.com/8Vwpg8T5GDQa1))

```javascript
customElements.define("event-delegator", class extends HTMLElement {
    _handleInnerClick(evt) {
        evt.preventDefault();
        evt.stopPropagation();
        alert(`You clicked inside me`);
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


### Triggering Events

Custom elements [can listen to events](#Listening-to-Events) but they become really useful as soon as they're triggering events themselves, as per usual, listening to events from Elm is easy. You mainly want to use this as an adapter to give Elm access to [Web APIs][html5-apis] it does not yet support in form of a core package or to embed functionality from external JavaScript libraries.

To demonstrate this we build a slightly more involved custom element `<copy-to-clipboard>` that lets the user copy text from an Elm app via button click using the [Document.execCommand API][doc-exec-command]. This is a fairly old non-standard API that's widely supported, nonetheless. The [Clipboard API][mdn-clipboard] is the modern successor, in case you don't need support for older browsers.

The gist is that our element listens for `click` events from its children, copies the value of its `text` attribute to the clipboard and triggers a [`CustomEvent`][mdn-customevent] notifying Elm that the operation has been successful, Elm can also decode event data being passed. ([demo](https://ellie-app.com/8VvL6ggT5qJa1))

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

_Note that IE needs [a polyfill for CustomEvent][mdn-customevent-polyfill]._

Many Elm apps use this technique to embed libraries like [CodeMirror](https://github.com/ellie-app/ellie/blob/a45637b81e2495ffada12f9a75dd6bb547a69226/assets/src/Ellie/Ui/CodeEditor.js) or [Google Maps](https://package.elm-lang.org/packages/PaackEng/elm-google-maps/latest/).

Until now all seems hunky-dory in the world of custom elements being embedded with Elm but there are some [gotchas](#Gotchas) you need to be aware of. We'll take a look at these in the next section.

## Gotchas
TODO

And while we're talking about gotchas...

## Browser Support

Looking at our basic example snippets you may have a very valid question. ([demo](https://ellie-app.com/8Vw6BbYYpc4a1))

```javascript
class MyElement extends HTMLElement {}
customElements.define("my-element", MyElement);
```

```elm
import Html

element =
    Html.node "my-element" [] [ Html.text "Awesome!" ]
```

> If that's all there is to it why do I even read this guide?

Glad you asked! As is usually the case, there's more than meets the eye.


### Older Environments

Our custom element works flawlessly... until we try to run the code using our fancy new `<my-element>` component in Internet Explorer or some ancient mobile browser, a webview - `SyntaxError` or maybe `"customElements" is not defined`. You probably know the drill by now, off to the "browser support" page; [looks very green and ready for showbiz][wc-home] but we remember [the word "polyfill"][wc-polyfills] everybody throws around so that is what catches our eye. Then our eyes glaze over at all the polyfill-o-babble. The gist is that not every browser supports web components out-of-the-box and some implementations are buggy so you need to include a sort-of base library. After we've dutifully included [the custom elements polyfill][wc-polyfill-custom-elements] our code agrees to run inside the mobile browser (and the webview?) but Internet Explorer is relentless, as always - `SyntaxError`, bane of our existence.

It turns out that Internet Explorer doesn't support the `class` syntax introduced in ES6, annoying. Because we know that `class` syntax is actually just syntactic sugar for ye olde function constructors and prototype chaining we begrudgingly rewrite our example component.

```javascript
function MyElement() {}
MyElement.prototype = Object.create(HTMLElement.prototype);
customElements.define("my-element", MyElement);
```
`IE: The custom element constructor did not produce the element being upgraded`, odd. After some more research we [come across the magic incantation][so-custom-elements] that makes our component appear in all browsers. Note that the polyfill detects modern browsers automatically now so we at least don't need to [patch the native implementation manually to work with ES5 style classes][wc-polyfill-custom-elements-es5], it is done for us. This means that per spec native custom element implementations only work with ES6 classes, keep that in mind!

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

I know what you're thinking, I've had that same epiphany, too.

> Let me get this straight, for cross browser support I need a polyfill for old browsers *and* modern browsers?

Ye.. well, that's not the whole story. It's not the only solution since you can serve different bundles to different browsers like [Angular 8+ differential loading][ng-differential-loading] does. Which is not the ultimate salvation it's made out to be. Believe me when I say that having essentially two different code base versions of your app run in older and newer browsers respectively can lead to bugs that are very hard track down; I'm looking at you `uglify-js` and you Angular and your globally enabled `unsafe-optimizations`. But that's a story for another day.

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

If we open this in Chrome our button is indeed a button with an orange background. Safari does not concur, neither does pre-Chromium Microsoft Edge, nor [any Webkit based browser possibly forever][webkit-nope] which includes the iOS browser. `Customized built-in` s as they're called are part of the spec but may as well not be because a non-significant amount of browsers doesn't and probably won't support them anytime soon. Although there is [a polyfill][customized-polyfill] my advice would be to ignore that part of the spec, it's not safe to use as [is documented in this w3c issue][w3c-nope] and layering ever increasing mountains of polyfills and shims onto each other might have consequences.

[customized-polyfill]: https://github.com/ungap/custom-elements-builtin 
[webkit-nope]: https://bugs.webkit.org/show_bug.cgi?id=182671 
[w3c-nope]: https://github.com/w3c/webcomponents/issues/509 


### Bundling

Speaking of which, let us finally address the elephant in the room. You're probably

TODO


* [ ] Bundler compatibility (ES6 classes vs transpilers)
    - [ ] Include a parcel example
    - [ ] Include a webpack example
    - [ ] Include an elm-live example
* [ ] Conclusion

## Conclusion
TODO

## Further Reading

* [Alex Korban's A Straight Forwared Introduction to Custom Elements](https://korban.net/posts/elm/2018-09-17-introduction-custom-elements-shadow-dom/)


[mdn-clipboard]: https://developer.mozilla.org/en-US/docs/Web/API/Clipboard_API 
[doc-exec-command]: https://developer.mozilla.org/en-US/docs/Web/API/Document/execCommand 
[elmpkg-elm-json]: https://package.elm-lang.org/packages/elm/json/latest
[jq-event-delegation]: https://learn.jquery.com/events/event-delegation/ 
[guide]: https://guide.elm-lang.org
[guide-interop]: https://guide.elm-lang.org/interop/
[guide-ports]: https://guide.elm-lang.org/interop/ports.html 
[guide-custom-elements]:https://guide.elm-lang.org/interop/custom_elements.html 
[html5-apis]: https://developer.mozilla.org/en-US/docs/Web/API 
[mdn-customevent]: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent
[mdn-customevent-polyfill]: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent#Polyfill
[mdn-event-bubbling]: https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Building_blocks/Events#Event_bubbling_and_capture 
[mdn-slot]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/slot 
[mdn-wc]: https://developer.mozilla.org/en-US/docs/Web/Web_Components 
[module-amd]: http://wiki.commonjs.org/wiki/Modules/AsynchronousDefinition
[module-commonjs]: http://wiki.commonjs.org/wiki/Modules/1.1.1 
[module-meteor]: https://docs.meteor.com/api/packagejs.html
[oop-backbone]: https://github.com/jashkenas/backbone/blob/1.4.0/backbone.js#L398
[oop-base2]: https://github.com/meritt/base2/blob/1.0/src/base2.js#L59
[oop-dojo]: https://github.com/dojo/dojo/blob/1.16.2/_base/declare.js
[oop-ember]: https://github.com/emberjs/ember.js/blob/v3.18.1/packages/@ember/-internals/runtime/lib/system/core_object.js
[oop-extjs]: https://docs.sencha.com/extjs/6.2.0/modern/Ext.html#method-define
[oop-yui]: https://github.com/yui/yui3/blob/v3.18.1/src/oop/js/oop.js
[w3c]: https://www.w3.org/ 
[wc-custom-elements]:https://www.webcomponents.org/specs#the-custom-elements-specification 
[wc-home]: https://www.webcomponents.org/
[wc-polyfills]: https://www.webcomponents.org/polyfills 
[wc-polyfill-custom-elements]: https://github.com/webcomponents/polyfills/tree/master/packages/custom-elements
[wc-polyfill-custom-elements-es5]: https://github.com/webcomponents/polyfills/tree/master/packages/custom-elements#es5-vs-es2015 
[wc-specs]: https://www.webcomponents.org/specs
