# CoreBridge Demo

**A one-screen iOS app that makes a C-ABI boundary visible: tokens arriving under credit-based backpressure, faults you can flip at runtime, and the diagnostics counters that move when you do.**

This is the runnable companion to **[core-bridge-kit](https://github.com/rajatslakhina/core-bridge-kit)** — a typed, cancellable, back-pressured `AsyncSequence` over a transport that can carry nothing but scalars and a function pointer. The library is a Swift package with no app target; this is a separate Xcode project that consumes it as a **remote package dependency pinned to exactly `v1.1.0`**, exactly the way a real consumer would.

## Why this matters

The interesting failure modes at a shared-core boundary are invisible in a code review and obvious the moment you can watch them:

- **Backpressure.** The credit window is two, so the core may run at most two tokens ahead of the view. Text arrives in a steady trickle rather than a burst — and that *is* the flow control, not a `Task.sleep` pretending to be one.
- **A core that ignores credits.** Flip *Core ignores credits* and run again: the stream dies immediately with a flow-control violation, and `Flow-control violations` ticks to 1. Without the check, that same core would have quietly buffered its entire output into your heap.
- **A late callback after release.** Flip *Core calls back after release* and watch `Stale frames dropped`. In a bridge that identified calls by a bare index or pointer, that frame would have landed on whichever call inherited the slot.
- **A frame kind from a newer core.** Flip *unknown frame kind*: it is counted and skipped, and the stream still completes intact.
- **A core that never terminates.** Flip it, then press Cancel: the call is reclaimed rather than left hanging.

The app owns the content — the narration streamed back lives in `DemoApp.swift`, not in the library, because a boundary library has no business shipping copy. The library owns the boundary and nothing else.

## Screenshots

**None.** This project was produced by an unattended scheduled run, which cannot be granted control of the Simulator. The verbatim refusal was:

> Computer-use access to "Simulator" can't be approved during a scheduled run. To grant it, send a message in this conversation (the approval card will appear), or add the app to the scheduled task's settings. (Retrying returns this same result.)

So there is no screenshot here, and no `Demo/Screenshots/` directory, because there is nothing honest to put in one. See **Verification** below for exactly what *was* checked.

## Design decisions, and what was rejected

**An exact version pin, not `from:` and not a branch.** The obvious default, `upToNextMajorVersion` / `from: "1.1.0"`, silently resolves to whatever `1.x` exists on the day someone clones this. Branch-tracking (`branch = main`) is worse: every clone and every CI run gets whatever `main` happened to be that morning. For a portfolio artifact the property that matters is that this project builds the same way in a year as it does today, so the requirement is `kind = exactVersion; version = 1.1.0`. The cost — this repo does not pick up library fixes by itself — is the point, not an oversight.

**A remote package reference, not a local path.** A `.package(path: "../core-bridge-kit")` reference would build faster and prove nothing: it only works on a machine that already has the library checked out next door. The remote reference means CI has to resolve the real repository at the real tag over the network, which is the same thing a stranger's clone does.

**Two repositories, not one with a nested example app.** An example target inside the package builds against the working tree, so it can pass while the *published* package is broken. Splitting them makes the dependency edge real and testable. The cost is two repos to keep in step, paid for by the version pin above.

**`generic/platform=iOS Simulator` in CI, not a named device.** `-destination 'name=iPhone 16,OS=latest'` ties the job to whichever simulator *runtimes* that day's runner image ships, which are not guaranteed; a compile-only check needs no device to exist.

**The app owns the content; the library owns the boundary.** The narration streamed back lives in `DemoApp.swift`. The alternative — shipping sample copy inside `CoreBridge` — would put product text in a boundary library and make the package heavier for every consumer that has its own core.

## How to run it

```bash
git clone https://github.com/rajatslakhina/core-bridge-kit-demo-app.git
cd core-bridge-kit-demo-app
open Demo.xcodeproj
```

Then in Xcode: select the **Demo** scheme (it is committed as a shared scheme, so it is there on a fresh clone), pick any iOS Simulator, and **⌘R**. Xcode resolves `core-bridge-kit` from GitHub at `v1.1.0` on first open — the package requirement is `kind = exactVersion`, so it resolves to that tag and nothing else. The stream starts on appear — you should see text filling in a word at a time, and the diagnostics list at the bottom updating as it goes.

## Verification — what actually happened

Stated precisely, because "it builds" and "it runs" are different claims and only one of them is true here:

| Claim | Status |
|---|---|
| Library builds and tests clean, warnings as errors, from a cold `.build` | **Verified** — `swift build`/`swift test`, Swift 6.0.3, 57 tests, 0 failures. Re-run in [the library's CI](https://github.com/rajatslakhina/core-bridge-kit/actions) on `swift:6.0`. |
| Library compiles for iOS Simulator | **Verified** — `macos-15` job in the library's CI. |
| `Demo.xcodeproj` resolves the remote package from GitHub at `v1.1.0` | **Checked by CI on every push** — the `build` job runs `xcodebuild -resolvePackageDependencies` and prints the resulting `Package.resolved`. See the [Actions tab](../../actions) for the current result. |
| Demo app compiles against the resolved library | **Checked by CI on every push** — `xcodebuild build -destination 'generic/platform=iOS Simulator'`. See the [Actions tab](../../actions). |
| `project.pbxproj` is structurally sound | **Verified** — brace/paren balance and every object reference checked against its definition before commit. |
| **Demo app launched and ran on a Simulator** | **NOT DONE.** Computer-use was refused (quoted above). Nobody has watched this app run. |
| **Screenshots of the running app** | **NOT DONE.** No images exist. |

The CI job is the closest honest substitute for a human opening the project: it proves the remote dependency genuinely resolves from GitHub at the pinned tag and that the app target compiles against it. It does not prove the app launches, and this README does not claim it does.

Live status: [Actions tab](../../actions).

## License

MIT. See [LICENSE](LICENSE).
