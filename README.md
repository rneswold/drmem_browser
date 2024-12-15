# DrMem Browser

An application which interacts with a [DrMem](https://github.com/DrMemCS/drmem) node.

## Building the App

This application uses the [Flutter](https://flutter.dev/) framework, so you should be able to build the app to run on Android or iOS devices; browser pages; and MacOS, Linux, or Windows desktops.[^1] Install Flutter on your system. You can run `flutter doctor` to see if you're missing any toolkits needed to build to your platform.

This project was built using VSCode. If you wish to contribute, using VSCode is highly recommended. Be sure to install the Dart and Flutter extensions.

### Clone the Project

Pull the latest source from GitHub and dependencies from `pub.dev`:

```shell
$ git clone git@github.com:DrMemCS/drmem_browser.git
$ cd drmem_browser
$ flutter pub get
```

### Make a Development Branch

If you plan to contribute changes to the project, create a development branch (the author uses `pull-request` for changes that aren't requested in an issue or `pr-issue#`, where `#` is the issue number, when working on an issue.)

```shell
$ git checkout -b pull-request
```

Before pushing your changes to GitHub, run `flutter test` to make sure your changes didn't break any features. Please add tests for the features you add, too.

After pushing your changes, GitHub will display a button which starts the "pull request" process. When the pull request is made, GitHub will make sure your changes can be merged and that all the tests pass before it allows the request to be merged with `main`.

### Building an Android Image

To build an Android release (a `.apk` file):

```shell
$ flutter build apk --target-platform android-arm64
```

It will build an image, `build/app/outputs/flutter-apk/app-release.apk`, which can be loaded on your Android device.

---

## TO-DO List

Here's an informal list of features to be added. If you're interested in helping, please open an issue indicating which feature you will be tackling.

- [X] Add a GitHib workflow to build and test before merging pull requests
- [X] Display all the devices defined by the node (in the node details page.)
- [X] Add an app icon
- [X] Sheets need to be added to persistent storage.
- [ ] Implement the Plot Row type.
  - [ ] Displaying plots
  - [ ] Editing plot configuration
  - [ ] Should support strip plots (numeric device(s) vs. time), logic plots (boolean device(s) vs.time), and X-Y (numeric device(s) vs. numeric device)
- [X] Must be able to set the value of settable devices.
- [ ] Add unit tests
- [ ] Finish Sheet Editor
  - [X] Add controls to add sheets
  - [X] Add controls to delete sheets
  - [X] Add panel with buttons to append new rows
  - [X] Allow rows to be reordered
  - [X] Add "Delete" icon to delete a row
  - [ ] Finish editor widgets for all row types
    - [X] Dividers
    - [X] Devices
    - [X] Comments
    - [ ] Plots
- [X] Create a "Widget" that implements the GraphQL API. Use the approach done by Bloc in which the `BuildContext` gains a field; in our case, a `drmem` field that has methods that use the GraphQL API.
  - [X] This widget should be extracted and packaged so that other developers can make their own Flutter apps that talk to DrMem.
  - [ ] Needs to monitor when it goes in and out of the background. As it transits through these states, it must:
    - [ ] Shutdown and restore the mDNS service.
    - [ ] Shutdown and restore GraphQL subscriptions.
  - [ ] Need to verify that all error handling is done correctly (re: GraphQL connections)

[^1]: This isn't entirely true. It uses a library that provides mDNS support and not all platforms are supported by it.
