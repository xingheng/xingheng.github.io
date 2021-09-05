---
layout: page
title: Set up a mac browser application based on cef3
description: "Setup steps on building mac client based on cef"
image:
  path: http://example.jpg
  feature: chrome-vs-chromium.jpeg
  credit: kompitren
  creditlink: https://www.kompitren.com/2017/06/perbedaan-antara-google-chrome-dan-chromium-browser/
tags: [cef, mac, objective-c, c++]
comments: true
reading_time: true
modified: 2017-12-24
---



The [Chromium Embedded Framework](https://bitbucket.org/chromiumembedded/cef/) (CEF) is a simple framework for embedding Chromium-based browsers in other applications. The [cef-project](https://bitbucket.org/chromiumembedded/cef-project) can be used as the starting point for third-party applications built using CEF.

&nbsp;

### Setup

1. Build project from [cef-project]((https://bitbucket.org/chromiumembedded/cef-project)).

   ```shell
   cd /path/to/cef-project
   mkdir product && cd product
   cmake -G "Xcode" -DPROJECT_ARCH="x86_64" -DWITH_EXAMPLES=Off  ..
   ```

2. The base example product target is `cefclient`, let's rename it.

   - To find the all related files and directories on `cefclient`.

     ```shell
     find . -type f -name "*cefclient*"
     find . -type d -name "*cefclient*"
     ```

   - Find and replace the string with case sensitive to replace `cefclient` with `mybrowser` in Sublime Text.app.

   - Replace the app icon with new *icns* file, update the new file name in `Info.plist` file if needed.

3. Remake it.

   ```shell
   cd product
   cmake .
   ```

&nbsp;

### Let's Play

1. Add new source files to project.

   - Create source files with Xcode file templates.
   - Add the relative file path to `CMakeLists.txt` to existing groups.
   - Remake.

2. Add image assets to project.

   - Convert the source png files to tiff file firstly.

     ```shell
     tiffutil -cathidpicheck background.png background@2x.png -out background.tiff
     ```

   - Move the assets to *third_party/cef/cef_binary_xxxx.xxxx/tests/mybrowser/resources/mac/* directory.

   - Add the relative file paths to `RESOURCES` group.

   - Remake.

   - Same with xib/nib files.

3. Add custom framework to project, such as ***Sparkle***.

   - Place the framework under the *third_party* directory, such as */third_party/Sparkle/Sparkle.framework*.

   - Edit the macOS configuration in file `CMakeLists.txt`.

     - Define the Sparkle.framework for later usage.

       ```cmake
       SET(SPARKLE_FRAMEWORK "${CMAKE_SOURCE_DIR}/third_party/Sparkle/Sparkle.framework")
       ```

     - Link against to the main target.

       ```make
       target_link_libraries(${CEF_TARGET} ${SPARKLE_FRAMEWORK})
       ```

       Since the original target already links to the `OpenGL` framework with function `target_link_libraries`, let's append it after it.

       ```cmake
       target_link_libraries(${CEF_TARGET} libcef_lib libcef_dll_wrapper ${CEF_STANDARD_LIBS} "-framework OpenGL" ${SPARKLE_FRAMEWORK})
       ```

     - Copy the framework to main app bundle.

       ```
       # Copy the Sparkle framework into the Frameworks directory.
       COMMAND ${CMAKE_COMMAND} -E copy_directory
               "${SPARKLE_FRAMEWORK}"
               "${CEF_APP}/Contents/Frameworks/Sparkle.framework"
       ```

     - Specify the `RUNPATH` to make the framework loaded.

       ```cmake
       set_target_properties(${CEF_TARGET} PROPERTIES INSTALL_RPATH "@executable_path/..;@loader_path/../Frameworks")
       set_target_properties(${CEF_TARGET} PROPERTIES BUILD_WITH_INSTALL_RPATH TRUE)
       ```

   - Remake it!