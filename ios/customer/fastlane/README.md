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

Build only (no upload)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload to App Store Connect (TestFlight)

### ios release

```sh
[bundle exec] fastlane ios release
```

Build and upload to App Store Connect for release

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Take App Store screenshots

### ios screenshots_quick

```sh
[bundle exec] fastlane ios screenshots_quick
```

Take screenshots for a single device (faster for testing)

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Upload metadata only (no build, no screenshots)

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload screenshots only

### ios full_release

```sh
[bundle exec] fastlane ios full_release
```

Full release: screenshots + metadata + build + upload

### ios refresh

```sh
[bundle exec] fastlane ios refresh
```

Refresh metadata and screenshots only (no new build)

### ios submit_review

```sh
[bundle exec] fastlane ios submit_review
```

Submit the app for App Store review

### ios bump_version

```sh
[bundle exec] fastlane ios bump_version
```

Increment version number (major.minor.patch)

### ios bump_build

```sh
[bundle exec] fastlane ios bump_build
```

Increment build number only

### ios download_metadata

```sh
[bundle exec] fastlane ios download_metadata
```

Download existing metadata from App Store Connect

### ios sync_certs

```sh
[bundle exec] fastlane ios sync_certs
```

Sync certificates and provisioning profiles

### ios add_device

```sh
[bundle exec] fastlane ios add_device
```

Register new devices

### ios test

```sh
[bundle exec] fastlane ios test
```

Run tests

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
