## Photos.framework test app for macOS

A simple project to demonstrate access the Photos library from a macOS application.

Frustratingly, Photos.framework on macOS does not expose `+[PHAsset fetchAssetsWithOptions:]` in its headers, so this declaration has to be included in the application source code. This probably means that Apple would not accept its use in the Mac App Store.
