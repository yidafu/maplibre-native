{
  "targets": [
    {
      "target_name": "mbgl",
      "cflags!": [ "-fno-exceptions" ],
      "cflags_cc!": [ "-fno-exceptions" ],
      "cflags_cc": [ "-std=c++17", "-fexceptions" ],
      "xcode_settings": {
        "GCC_ENABLE_CPP_EXCEPTIONS": "YES"
      },
      "defines": [
        "NODE_GYP_MODULE_NAME=mbgl",
        "BUILDING_NODE_EXTENSION",
        "_LARGEFILE_SOURCE",
        "_FILE_OFFSET_BITS=64"
      ],
      "include_dirs": [
        "/Users/yidafu/github/maplibre-native/platform/node/node_modules/node-addon-api",
        "/Users/yidafu/Library/Caches/node-gyp/24.8.0/include/node",
        "./src",
        "../../include",
        "../../platform/default/include",
        "../../vendor/boost/include",
        "../../vendor/icu/include",
        "../../vendor/earcut/include",
        "../../vendor/shelf-pack/include",
        "../../vendor/kdbush/include",
        "../../vendor/maplibre-native-base/deps/geometry.hpp/include",
        "../../vendor/maplibre-native-base/deps/variant/include",
        "../../vendor/maplibre-native-base/deps/geojson.hpp/include",
        "../../vendor/maplibre-native-base/include",
        "./include"
      ],
      "sources": [
        "./src/node_map.cpp",
        "./src/node_request.cpp",
        "./src/node_feature.cpp",
        "./src/node_logging.cpp",
        "./src/node_expression.cpp",
        "./src/node_mapbox_gl_native.cpp"
      ],
      "libraries": [],
      "dependencies": [
        "<!(node -p \"require('node-addon-api').gyp\")"
      ],
      "conditions": [
        [
          "OS=='mac'",
          {
            "defines": ["_DARWIN_USE_64_BIT_INODE=1"],
            "xcode_settings": {
              "OTHER_CFLAGS": ["-fno-omit-frame-pointer"],
              "OTHER_CPLUSPLUSFLAGS": ["-fno-omit-frame-pointer"],
              "MACOSX_DEPLOYMENT_TARGET": "10.15"
            },
            "link_settings": {
              "libraries": [
                "-undefined dynamic_lookup",
                "-bind_at_load"
              ]
            }
          }
        ],
        [
          "OS=='linux'",
          {
            "link_settings": {
              "libraries": ["-z now"]
            }
          }
        ],
        [
          "OS=='win'",
          {
            "defines": ["NOMINMAX"],
            "msvs_settings": {
              "VCCLCompilerTool": {
                "AdditionalOptions": ["/Zc:__cplusplus"]
              }
            }
          }
        ]
      ]
    }
  ]
}