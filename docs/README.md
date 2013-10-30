# Terms

- "Protected": instance variable or function that begins with an underscore (ie `@_loadComplex: () ->`). Should only be used by subclasses
- "Attribute": `Backbone.Model` that can be changed via `@get('name')` or `set('name', value, options)`
- "Property": instance variable on the model (ie `@propertyName`)
- "Method": instance function on the model (ie `@isDirty()`)
- "Event": event fired on the Model (ie `@on 'ui:saved', () ->`)
- "Singletons": Only one instance of this exists in the runtime


# Naming Conventions

- `ALL_CAPS`: Enum or Singleton
- `_startsWithUnder`: "Protected" variable or method (only to be used by subclasses)
- `camelCase`: local variable/function or instance variable/function
- `ClassName`: class or variable containing a constructor


# Components Overview

## Abstract Models

- manipulate relationships
- fire `child:add/remove` events and trickle up
- keep lists (`Backbone.Collection`) of `getChildren()`
- **do not** set HTML

## Saveable Models

- implement `_loadComplex()`
- `serialize()`
- `parse()` (send `parse: true` in options)
- `onReloaded()`
- `onSaved()`

## Remote updater

- refers to set of models (`allContent` Singleton)
- fires `reloaded` on models
- remembers hash of last commit

## Saver

- listens to all models
- sets dirty flag (unless `options.parse` is set)

# UI State

Models may contain state that is not saved (only used for UI).
These are defined as `Backbone.Model` attributes that begin with `ui:`.

- `ui:unsaved` **boolean**: this model has unsaved local changes
- `ui:selected` **boolean**: this model is selected (currently showing in the content editor, or currently in the sidebar)
- `ui:original` **JSON**: the most recently loaded JSON object

# Events

**Note:** when an event is caused by a remote update, the `{remote:true}` option will be sent along with the event

- The usual `change:*` events
- `toc:add/remove/move`
- HTML `resource:add/remove` : Notify when resources (images) are added/removed


# Abstract Models

## Saveable

- Attributes:
    - `id`: always an absolute href from the root of the EPUB 
    - `ui:unsaved`: **boolean** denotes there are local changes to this model
- Events (optional):
    - `loaded`
    - `reloaded`
    - `saved`
- Methods:
    - defines `load()`: returns a promise
    - defines `reload()`: returns a promise
    - defines `isDirty()`: **NOTE:** use this method instead of checking `ui:dirty` because a Book can be dirty if the OPF **OR** the NavPage have unsaved changes
    - abstract `onReloaded()`: returns `true` if there are **NO** local changes
    - abstract `_loadComplex()` (used by `load()` if the model needs more than a single `fetch()` to "load" itself
    - abstract `onSaved()` (called by `SAVER`)

## TreeItem

Mixin that provides a tree structure:

- `getChildren()`
- `getParent()`
- `getRoot()`
- `dfs( (model) -> )` returns the first match defined by iterator or `null` using a depth-first-search
- `bfs( (model) -> )` returns the first match defined by iterator or `null` using a breadth-first-search
- `addChild(child, at)`
- `removeChild(child, options)`
- `newNode(options)` defined **only** on the root; returns a new `Backbone.Model` using the options passed in

## Book (extends Saveable and TreeItem)

- Properties:
    - `_tocNodes` Collection of all leaf nodes (for easy lookup)
- abstract `getToc()` returns the `TocPage` (or self in the case of `atc`)

## Page (extends Saveable)

- `change:body` (possibly also with `{remote:true}` option)
- `resource:add/remove` (**Note:** Maybe this should be done by `xhtml-file`?)

## TocPage (extends Page)

- extends `Page`
- `getChildren()` and fires `child:add/remove/move` (possibly also with `{remote:true}` option)
- the `Book` is passed in to the constructor
- listens to `toc:add/remove/move` and updates the HTML
- **Note:** abstract `serialize()` and `parse()` are still undefined

## TocItem (extends TreeItem)

- `getPage()` returns a `Page` or `null` if it does not point to a Page (like a chapter or unit)
- Optionally can store a `title` attribute (overridden title)
- **Note:** abstract `addChild` is still undefined


# Concrete Models

## opf-file (Book)

- `serialize()`: return an OPF XML file
- `parse()`: Parse an OPF XML file. Add all `<manifest/>` items to `ALL_CONTENT`
- `saved()`: clear all "local changes"
- `reloaded()`: replay local changes
    - always add `<manifest>` items (never remove, just to be safe)
    - **DO NOT** redo local property changes like `title`, `isbn`, etc (instead let the user know they were changed remotely; to reduce thrashing)

Notes:

- (Optional) fires `item:add/remove` (also called because of remote changes with `{remote:true}` option)
- listens to `toc:add/remove` and `resource:add/remove` to update the `<manifest/>` items

## xhtml-file (Page)

- `serialize()`: return `@get('body')` and `@('head')` (and maybe `title`)
- `parse()`: set `@set('body')`, `head`, and `title`
- `reloaded()`: use `jsdifflib` to find changes (and detect conflicts; use the remote one when conflict occurs)

## toc-node (TocItem)

- defines `addChild(model, at)` which either links to the child or creates a Copy (if it is a different book)
- contains an overridden `title` property if there is one
    - **NOTE:** ToC views should use `@.toJSON().title` instead of `@get('title')` when rendering the ToC to ge the correct title (in the book context)

## toc-file (TocPage)

- extends `xhtml-file`
- `getChildren()`
- fires `child:add/remove/move`

