fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build

```sh
[bundle exec] fastlane ios build
```

Resolve packages, run tests, build a Release archive

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Upload a beta build to TestFlight

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Upload localised store metadata only (no build, no screenshots)

### ios release

```sh
[bundle exec] fastlane ios release
```

Archive and upload build + localised metadata to App Store Connect

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
