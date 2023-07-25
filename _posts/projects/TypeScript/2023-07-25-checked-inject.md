---
layout: post
title: checked-inject
subtitle: TypeScript dependency injection with compile-time verification
gh-repo: youngspe/checked-inject
gh-badge: [star, follow]
# tags: [test]
# comments: true
# cover-img: /assets/img/path.jpg
# thumbnail-img: /assets/img/thumb.png
# share-img: /assets/img/path.jpg
date: 2023-07-25 11:00:00
---


Links:
[source](https://github.com/youngspe/checked-inject),
[documentation](https://youngspe.github.io/checked-inject/),
[npm](https://www.npmjs.com/package/checked-inject)

This started as personal learning experiment to create a dependency injection library.
I soon realized the entire dependency graph could be represented in the type system,
and can be enforced statically when requesting a resource from the DI container.
This includes considering whether:
* A dependency has been provided
* A dependency can be resolved synchronously
* The request is made within the scopes associated with each dependency

After a few weeks of tinkering around with types, `checked-inject` was born!

Here's an example of a simple application that compiles and runs successfully:

```ts
import { TypeKey, Module, Inject, Injectable } from 'checked-inject'

// TypeKeys are like named dependencies. They're not tied to a specific class
// object, but uniquely identify a resource of the given type:
class NameKey extends TypeKey<string>() { private _: any }
class IdKey extends TypeKey<number>() { private _: any }

class User extends Injectable {
  name: string
  id: number
  constructor(name: string, id: number) {
    this.name = name; this.id = id
  }

  // 'inject' describes how to resolve this class when an explicit provider is
  // not given:
  static inject = Inject.construct(this, NameKey, IdKey)
}

class App {
  user: User
  constructor(user: User) {
    this.user = user
  }
}

// A module defines a set of providers and scopes to add to a container:
const UserModule = Module(ct => ct
  // TypeKeys can be explicitly provided to a container:
  .provideInstance(NameKey, 'Alice')
  .provideInstance(IdKey, 123)
)

// This module combines UserModule with an additional provider:
const AppModule = Module(UserModule, ct => ct
  // Classes can also be explicitly provided rather than using the static
  // 'inject' field:
  .provide(App, { user: User }, ({ user }) => new App(user))
)

// 'inject' resolves the requested dependencies and passes them to the lambda:
AppModule.inject({ app: App }, ({ app }) => {
  console.log(`Welcome, ${app.user.name}`)
})
```

However, if we were to remove the line `.provideInstance(NameKey, 'Alice')` we would get an error that ends with:

```
... Type 'void' is not assignable to type 'typeof NameKey'
```

indicating that the request is not safe to make because `NameKey` has not been provided.

## Structured Dependency Keys

When requesting resources, in addition to classes or TypeKeys, you can request multiple resources
by structuring keys into arrays or objects:

```ts
const [name, id, user] = container.request([NameKey, IdKey.Provider(), User])
```

```ts
const { name, id, user } = container.request({
  name: NameKey,
  id: IdKey.Provider(),
  user: User,
})
```

You can use this pattern to declare multiple dependencies in a provider:

```ts
const container = Container.create()
  .provide(UserKey, {
    name: NameKey,
    id: IdKey,
  }, ({ name, id }) => new User(name, id))
```

## Dependency Operators

Operators produce ComputedKeys that change how a dependency is resolved.
TypeKeys, ComputedKeys, and class objects that extend `Injectable` have methods that apply these operators.
For structured keys and classes that do not extend `Injectable`, you can use equivalent functions in the Inject namespace.

### Lazy and Provider

The `.Lazy()` and `.Provider()` operators (equivalent to `Inject.lazy(src)` and `Inject.provider(src)`)
evaluate to functions that provide the requested type.
Lazy caches the output after the first invocation, and provider creates a new instance for each invocation.

```ts
// Request a lazy dependency using the 'Injectable.Lazy()' method:
container.inject({ user: User.Lazy() }, ({ user }) => { console.log(user().name) })
// Request a dependency provider using the 'Inject.provider(src)' function:
container.inject({ user: Inject.provider(User) }, ({ user }) => { console.log(user().name) })
```

### Async

The `.Async()` operator (equivalent to `Inject.async(src)`)
evaluates to a Promise that eventually yields the requested value.
This allows requesting async dependencies without having to use e.g. `requestAsync` or `injectAsync`:

```ts
// Request an async dependency using the 'Injectable.Async()' method:
container.inject({ user: User.Async() }, async ({ user }) => { console.log((await user).name) })
// Request an async dependency using the 'Inject.async(src)' function:
container.inject({ user: Inject.async(User) }, async ({ user }) => { console.log((await user).name) })
```

## Scoping

Scopes are used to manage the lifecycle of resolved resources.
If a resource is bound to one or more scopes, its instance will be reused as long as all the scopes are valid.
When a scope is added to a container, the scope is considered valid whenever a request is made to that specific container.
If a resource is not bound to a scope, a new instance will be resolved each time.

The `Singleton` scope is always valid and can be used to make sure a resource is only resolved once per container.

```ts
class UserScope extends Scope() { private _: any }
// A subcomponent describes a child container that assigns providers and scopes
// based on some parameters, in this case 'name' and 'id':
const UserComponent = Inject.subcomponent((ct, name: string, id: number ) => ct
  // UserScope allows us to cache dependencies that are only valid when a name
  // and id are available
  .addScope(UserScope)
  .provideInstance(NameKey, name)
  .provideInstance(IdKey, id)
)

const parent = Container.create()
  // Binding the 'User' resource to 'UserScope' allows us to cache a single
  // intance and return the same one every time 'User' is requested.
  // 'Singleton' would be insufficient because 'NameKey' and 'IdKey' are
  // provided in a child container, so they are unavailable in the Singleton
  // scope.
  .provide(User, UserScope, Inject.construct(NameKey, IdKey))

// The following statement would cause this error:
// ERROR: ... Type 'void' is not assignable to type 'typeof UserScope'
// const user1 = parent.request(User)

// The following three lines are equivalent:
const child1 = parent.request(UserComponent)('Alice', 123)
const child2 = parent.request(UserComponent.Build('Alice', 123))
const child3 = parent.build(UserComponent, 'Alice', 123)

// This is okay because child1 is in 'UserScope', and both 'NameKey' and 'IdKey'
// are provided:
const user2 = child1.request(User)
```

## Asynchronous Dependencies

You may want to have dependencies that are not immediately available--perhaps they
require data loaded from the disk or the network.
This library allows asynchronously providing and requesting dependencies:

```ts
let container = Container.create()
  .provideInstance(NameKey, 'Alice')
  // provide IdKey with an async function to simulate having to load it from IO
  .provideAsync(IdKey, {}, async () => 123)
  .provide(User, Inject.construct(User, NameKey, IdKey))

// This is okay since 'NameKey' is available synchronously:
let name1: string = container.request(NameKey)

// The following two statements would cause this error:
// ERROR: ... Type 'void' is not assignable to type 'NotSync<IdKey>'
// let id1: number = container.request(IdKey)
// let user1: User = container.request(User)

// The following are all allowed:
let name2: Promise<string> = container.requestAsync(NameKey)
let id2: Promise<number> = container.requestAsync(IdKey)
let user2: Promise<User> = container.requestAsync(User)
```

## Remarks

These were just a few examples of of what this library can do.
A more detailed guide is found in the [README](https://github.com/youngspe/checked-inject/blob/main/README.md).
If you have suggestions, feel free to open an issue and I'll take a look as soon as I can.
