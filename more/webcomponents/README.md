# A Guide to Using Elm With Webcomponents

This document is meant to be a practical usage guide to [the various web components specs][wc-specs] with the goal to provide you with the necessary tools to interop with web APIs that are not yet covered by Elm's core packages. The reason this guide exists is that most tutorials and documentation on web components just dump all the specs and some basic usage examples on you assuming that you already know the intricate details of why specific parts of the spec exist in the first place and what use case they try to solve. This situation can be daunting even for experienced web developers and even more so for newcomers. We aim to be as concise as possible while also providing sufficient information to get you up and running in no time.

## TL;DR
If you are looking for a quick start with Elm, Webcomponents and the setup of choice have a look at [the bundling section](#Bundling) where we have collected most of the setups people tend to use for their apps.

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

I've emphasized the most important information: in order to "use web components" you can and should actually pick and choose what part of the spec you need in order to solve your problem. You don't need to use Shadow DOM, if you don't need style encapsulation. You don't need to use HTML templates, if you already have a templating solution. You don't need ES Modules, if you have a compile-to-js language like, say, *drumroll* Elm. You may find yourself using these specs but they aren't usually necessary in conjuction with Elm.

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


## Custom Elements And Elm

Note that if at this point you skipped the earlier requests to have a look at the [interop section of the Elm guide][guide-interop] I'll try to nudge you again to do so... you may feel nudged now. 

So we've looked at [the specs][wc-specs] and the one I've skipped so far is actually the spec that's most relevant to Elm: [Custom Elements][wc-custom-elements]. Looking at the examples on that page, defining a custom element is easy enough.

```javascript
class MyElement extends HTMLElement {}
customElements.define("my-element", MyElement);
```

This unsurprisingly defines a new HTML element `<my-element>`. Note that the name *has* to include a hyphen and the class *needs* to extend `HTMLElement`. Here we see the raw power custom elements provide: they let you build your own HTML elements with behavior tailored to your application that are indistinguishable from built-in elements like `<input>` or `<section>`. Which in turn means we can create these kind of elements within Elm without problems, we've done it many times before.

```elm
import Html

view model =
    Html.node "my-element" [] [ Html.text "Awesome!" ]
```

Let's have a look at the anatomy of a custom element. Note that this only covers the part of the API that is most relevant to Elm, we provide links to associated concepts where appropriate.

### Construction

A custom element, just like any other built-in element, can be created declaratively using HTML or imperatively using JavaScript.

```javascript
customElements.define("twbs-alert", class extends HTMLElement {});
// ...
const element = document.createElement("twbs-alert");
```
```html
<!-- Note that custom elements can not be self-closing -->
<twbs-alert></twbs-alert>
```
```elm
import Html

btn =
    Html.node "twbs-alert" [] []
```

### Lifecycles

There are lifecycles you can attach clunkily-named callbacks to.

```javascript
customElements.define("twbs-alert", class extends HTMLElement {
    constructor() {
        // This <twbs-alert> is being initialized, it's not been
        // added to any document yet but you can initialize
        // your fields
    }
    adoptedCallback() {
        // This <twbs-alert> has been moved to a different document
    }
    connectedCallback() {
        // This <twbs-alert> has been added to the DOM
    }
    disconnectedCallback() {
        // This <twbs-alert> has been removed from the DOM
    }
});
```

### Attributes

Custom elements may declare supported attributes via `observedAttributes` - only attribute names returned from this trigger the `attributeChangedCallback` when changed. Note that attributes can only carry `string` values.

```javascript
customElements.define("twbs-alert", class extends HTMLElement {
    constructor() {
        this.classList.add('alert')
    }
    static get observedAttributes() {
        // We need to declare which attributes should be observed,
        // only these trigger the `attributeChangedCallback`
        return ['type'];
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
// ...
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
        -- or Html.Attributes.type_ "info"
        ]
        []
```

If you need to transfer object data you can use a [property](#Properties).

### Properties

Custom elements can declare properties via `get` and `set`, most kinds of JavaScript objects are supported.

```javascript
customElements.define("atla-trivia", class extends HTMLElement {
    constructor() {
        // Set up backing fields for your properties
        this._meta = null;
    }
    set meta(value) {
        // Sometimes it makes sense to "reflect" simple property values
        // back to corresponding attribute values, if any
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

With Elm you need to use a JSON encoder provided by the `elm/json` package.

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


* [ ] Attrs vs props performance
* [ ] Handling events

### Going Deeper

If you want to dive deeper into Webcomponents in plain JavaScript the [MDN page about Webcomponents][mdn-wc] is a good place to start.

### Gotchas
TODO

And while we're talking about gotchas...

## Browser Support

Looking at our basic example snippets you may have a very valid question

```javascript
class MyElement extends HTMLElement {}
customElements.define("my-element", MyElement);
```

```elm
import Html

view : Model -> Html msg
view model =
    Html.node "my-element" [] [ Html.text "Awesome!" ]
```
TODO: Ellie

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



[guide]: https://guide.elm-lang.org
[guide-interop]: https://guide.elm-lang.org/interop/
[guide-ports]: https://guide.elm-lang.org/interop/ports.html 
[guide-custom-elements]:https://guide.elm-lang.org/interop/custom_elements.html 
[mdn-customevent-polyfill]: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent#Polyfill
[wc-custom-elements]:https://www.webcomponents.org/specs#the-custom-elements-specification 
[wc-home]: https://www.webcomponents.org/
[wc-polyfills]: https://www.webcomponents.org/polyfills 
[wc-polyfill-custom-elements]: https://github.com/webcomponents/polyfills/tree/master/packages/custom-elements
[wc-polyfill-custom-elements-es5]: https://github.com/webcomponents/polyfills/tree/master/packages/custom-elements#es5-vs-es2015 
[wc-specs]: https://www.webcomponents.org/specs