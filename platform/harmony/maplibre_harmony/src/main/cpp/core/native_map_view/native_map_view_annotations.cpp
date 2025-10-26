napi_value NativeMapView::updateMarker(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== updateMarker() START ==========");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取 this 对象
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "updateMarker: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "updateMarker: Requires 1 argument (Marker object)");
        return undefined;
    }
    
    // 获取 NativeMapView 实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "updateMarker: Failed to unwrap NativeMapView instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "updateMarker: Map not initialized");
        return undefined;
    }
    
    // Unwrap Marker NAPI 对象
    maplibre::harmony::MarkerNAPI* marker = nullptr;
    if (napi_unwrap(env, args[0], reinterpret_cast<void**>(&marker)) != napi_ok || !marker) {
        Logger::error("NativeMapView", "updateMarker: Failed to unwrap Marker object");
        return undefined;
    }
    
    // 从 Marker 获取数据
    auto annotationId = marker->getAnnotationId();
    if (annotationId == static_cast<mbgl::AnnotationID>(-1)) {
        Logger::error("NativeMapView", "updateMarker: Marker has invalid ID (not added to map yet)");
        return undefined;
    }
    
    auto position = marker->getPositionPoint();
    auto iconId = marker->getIconId();
    
    Logger::info("NativeMapView", "[MarkerDebug] updateMarker: ID=%lu, lat=%f, lon=%f, icon=\"%s\"", 
                  annotationId, position.y, position.x, iconId.c_str());
    
    try {
        // 更新 Marker (使用 SymbolAnnotation)
        mbgl::SymbolAnnotation annotation(position, iconId);
        instance->map->updateAnnotation(annotationId, annotation);
        
        // 触发重绘
        instance->map->triggerRepaint();
        
        Logger::info("NativeMapView", "[MarkerDebug] updateMarker: Marker updated successfully");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "[MarkerDebug] updateMarker: Failed - %s", e.what());
    }
    
    Logger::info("NativeMapView", "========== updateMarker() END ==========");
    return undefined;
}

napi_value NativeMapView::addMarkers(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== addMarkers() START ==========");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取 this 对象
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "addMarkers: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "addMarkers: Requires 1 argument (markers array)");
        return undefined;
    }
    
    // 获取 NativeMapView 实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "addMarkers: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "addMarkers: Map not initialized");
        return undefined;
    }
    
    // 检查参数是否是数组
    bool isArray = false;
    if (napi_is_array(env, args[0], &isArray) != napi_ok || !isArray) {
        Logger::error("NativeMapView", "addMarkers: First argument must be an array");
        return undefined;
    }
    
    // 获取数组长度
    uint32_t length = 0;
    if (napi_get_array_length(env, args[0], &length) != napi_ok) {
        Logger::error("NativeMapView", "addMarkers: Failed to get array length");
        return undefined;
    }
    
    Logger::info("NativeMapView", "addMarkers: Processing %u markers", length);
    
    // 存储生成的 annotation IDs
    std::vector<mbgl::AnnotationID> ids;
    ids.reserve(length);
    
    // 遍历 Marker 数组（现在是 MarkerNAPI 对象）
    for (uint32_t i = 0; i < length; i++) {
        napi_value markerObj;
        if (napi_get_element(env, args[0], i, &markerObj) != napi_ok) {
            Logger::error("NativeMapView", "addMarkers: Failed to get marker at index %u", i);
            continue;
        }
        
        // Unwrap MarkerNAPI 对象
        maplibre::harmony::MarkerNAPI* marker = nullptr;
        if (napi_unwrap(env, markerObj, reinterpret_cast<void**>(&marker)) != napi_ok || !marker) {
            Logger::error("NativeMapView", "[MarkerDebug] NAPI-Error: Failed to unwrap Marker at index %u", i);
            continue;
        }
        
        // 直接从 MarkerNAPI 对象获取数据
        auto position = marker->getPositionPoint();
        auto iconId = marker->getIconId();
        
        // [MarkerDebug] 记录输入
        if (iconId.empty()) {
            Logger::warn("NativeMapView", "[MarkerDebug] NAPI-Input: marker[%u] has EMPTY icon, may not be visible!", i);
            Logger::warn("NativeMapView", "[MarkerDebug] NAPI-Warning: Use addAnnotationIcon() to add custom icon or ensure style has default marker icon");
        }
        
        Logger::info("NativeMapView", "[MarkerDebug] NAPI-Input: marker[%u] lat=%f, lon=%f, icon=\"%s\"", 
                     i, position.y, position.x, iconId.empty() ? "(empty)" : iconId.c_str());
        
        try {
            // 创建 SymbolAnnotation
            mbgl::SymbolAnnotation annotation(position, iconId);
            
            // 添加到地图并获取 ID
            mbgl::AnnotationID annotationId = instance->map->addAnnotation(annotation);
            ids.push_back(annotationId);
            
            // 设置 annotation ID 回 Marker
            marker->setAnnotationId(annotationId);
            
            Logger::info("NativeMapView", "[MarkerDebug] NAPI-Result: marker[%u] created with ID=%llu", i, annotationId);
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "[MarkerDebug] NAPI-Error: marker[%u] failed to add - %s", i, e.what());
        }
    }
    
    // [MarkerDebug] 统计添加结果
    Logger::info("NativeMapView", "[MarkerDebug] NAPI-Summary: Added %zu/%u markers successfully", ids.size(), length);
    if (ids.size() < length) {
        Logger::warn("NativeMapView", "[MarkerDebug] NAPI-Summary: ⚠️ %u markers failed to add", length - static_cast<uint32_t>(ids.size()));
    }
    
    // 触发重绘
    if (!ids.empty()) {
        try {
            instance->map->triggerRepaint();
            Logger::info("NativeMapView", "[MarkerDebug] NAPI-Repaint: Repaint triggered for %zu markers", ids.size());
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "[MarkerDebug] NAPI-Repaint: Failed to trigger repaint - %s", e.what());
        }
    } else {
        Logger::warn("NativeMapView", "[MarkerDebug] NAPI-Repaint: ⚠️ No markers added, skipping repaint");
    }
    
    // 创建返回的 ID 数组
    napi_value resultArray;
    if (napi_create_array_with_length(env, ids.size(), &resultArray) != napi_ok) {
        Logger::error("NativeMapView", "addMarkers: Failed to create result array");
        return undefined;
    }
    
    // 填充 ID 数组
    for (size_t i = 0; i < ids.size(); i++) {
        napi_value idValue;
        if (napi_create_int64(env, static_cast<int64_t>(ids[i]), &idValue) == napi_ok) {
            napi_set_element(env, resultArray, i, idValue);
        }
    }
    
    Logger::info("NativeMapView", "========== addMarkers() END - SUCCESS ==========");
    return resultArray;
}

napi_value NativeMapView::onLowMemory(napi_env env, napi_callback_info info) {
    // 低内存处理由 Harmony 系统管理
    // Low memory handling delegated to Harmony system
    Logger::debug("NativeMapView", "onLowMemory: Low memory handling delegated to Harmony system");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::setDebug(napi_env env, napi_callback_info info) {
    // Debug 可视化功能未在 Harmony 平台实现
    // Debug visualization not implemented for Harmony platform
    Logger::debug("NativeMapView", "setDebug: Debug visualization not implemented for Harmony platform");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getDebug(napi_env env, napi_callback_info info) {
    // Debug 可视化功能未在 Harmony 平台实现
    // Debug visualization not implemented for Harmony platform
    Logger::debug("NativeMapView", "getDebug: Debug visualization not implemented for Harmony platform");
    
    napi_value result;
    napi_get_boolean(env, false, &result);
    return result;
}

napi_value NativeMapView::getActionJournalLogFiles(napi_env env, napi_callback_info info) {
    // Action journal 需要 ActionJournal 支持，未在 Harmony 配置
    // Action journal requires ActionJournal support, not configured for Harmony
    Logger::debug("NativeMapView", "getActionJournalLogFiles: Action journal not configured for Harmony");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::getActionJournalLog(napi_env env, napi_callback_info info) {
    // Action journal 需要 ActionJournal 支持，未在 Harmony 配置
    // Action journal requires ActionJournal support, not configured for Harmony
    Logger::debug("NativeMapView", "getActionJournalLog: Action journal not configured for Harmony");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::clearActionJournalLog(napi_env env, napi_callback_info info) {
    // Action journal 需要 ActionJournal 支持，未在 Harmony 配置
    // Action journal requires ActionJournal support, not configured for Harmony
    Logger::debug("NativeMapView", "clearActionJournalLog: Action journal not configured for Harmony");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    return undefined;
}

napi_value NativeMapView::isFullyLoaded(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "isFullyLoaded() called");
    
    napi_value result;
    napi_get_boolean(env, false, &result);
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::warn("NativeMapView", "isFullyLoaded: Map not initialized, returning false");
        return result;
    }
    
    try {
        bool loaded = instance->map->isFullyLoaded();
        napi_get_boolean(env, loaded, &result);
        Logger::debug("NativeMapView", "isFullyLoaded: %s", loaded ? "true" : "false");
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "isFullyLoaded: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::getStyle(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getStyle() called");
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::warn("NativeMapView", "getStyle: Failed to unwrap instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    if (!instance->map) {
        Logger::warn("NativeMapView", "getStyle: Map not initialized");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 获取 Style 构造函数
    napi_value styleConstructor;
    napi_status status = napi_get_reference_value(env, maplibre::harmony::StyleNAPI::constructor, &styleConstructor);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "getStyle: Failed to get Style constructor");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    // 创建参数：mapPtr
    napi_value args[1];
    int64_t mapPtr = reinterpret_cast<int64_t>(instance->map.get());
    napi_create_int64(env, mapPtr, &args[0]);
    
    // 创建 StyleNAPI 实例
    napi_value styleInstance;
    status = napi_new_instance(env, styleConstructor, 1, args, &styleInstance);
    if (status != napi_ok) {
        Logger::error("NativeMapView", "getStyle: Failed to create Style instance");
        napi_value result;
        napi_get_null(env, &result);
        return result;
    }
    
    Logger::debug("NativeMapView", "getStyle: Style instance created successfully");
    return styleInstance;
}

napi_value NativeMapView::getMetersPerPixelAtLatitude(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getMetersPerPixelAtLatitude() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    
    napi_value result;
    napi_create_double(env, 0.0, &result);
    
    if (args.HasError()) {
        return result;
    }
    
    double latitude = args.GetDouble(0, "latitude");
    double zoom = args.GetDouble(1, "zoom");
    if (args.HasError()) {
        return result;
    }
    
    try {
        double metersPerPixel = mbgl::Projection::getMetersPerPixelAtLatitude(latitude, zoom);
        napi_create_double(env, metersPerPixel, &result);
        Logger::debug("NativeMapView", "getMetersPerPixelAtLatitude: lat=%f, zoom=%f, result=%f", latitude, zoom, metersPerPixel);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getMetersPerPixelAtLatitude: Failed - %s", e.what());
    }
    
    return result;
}

napi_value NativeMapView::projectedMetersForLatLng(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "projectedMetersForLatLng() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    double latitude = args.GetDouble(0, "latitude");
    double longitude = args.GetDouble(1, "longitude");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        mbgl::ProjectedMeters projectedMeters = mbgl::Projection::projectedMetersForLatLng(
            mbgl::LatLng(latitude, longitude)
        );
        
        napi_value result = ProjectedMetersHarmony::CreateProjectedMetersObject(env, projectedMeters);
        Logger::debug("NativeMapView", "projectedMetersForLatLng: lat=%f, lng=%f -> northing=%f, easting=%f", 
                      latitude, longitude, projectedMeters.northing(), projectedMeters.easting());
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "projectedMetersForLatLng: Failed - %s", e.what());
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
}

napi_value NativeMapView::pixelForLatLng(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "pixelForLatLng() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "pixelForLatLng: Map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    double latitude = args.GetDouble(0, "latitude");
    double longitude = args.GetDouble(1, "longitude");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        mbgl::ScreenCoordinate pixel = instance->map->pixelForLatLng(mbgl::LatLng(latitude, longitude));
        napi_value result = PointHarmony::CreatePointObject(env, pixel);
        Logger::debug("NativeMapView", "pixelForLatLng: lat=%f, lng=%f -> x=%f, y=%f", 
                      latitude, longitude, pixel.x, pixel.y);
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "pixelForLatLng: Failed - %s", e.what());
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
}

napi_value NativeMapView::pixelsForLatLngs(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "pixelsForLatLngs() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现数组参数解析和结果数组返回
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:772-796
    Logger::warn("NativeMapView", "pixelsForLatLngs: Not implemented - requires array parameter parsing");
    
    return undefined;
}

napi_value NativeMapView::latLngForProjectedMeters(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "latLngForProjectedMeters() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    double northing = args.GetDouble(0, "northing");
    double easting = args.GetDouble(1, "easting");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        mbgl::LatLng latLng = mbgl::Projection::latLngForProjectedMeters(
            mbgl::ProjectedMeters(northing, easting)
        );
        
        napi_value result = LatLngHarmony::CreateLatLngObject(env, latLng);
        Logger::debug("NativeMapView", "latLngForProjectedMeters: northing=%f, easting=%f -> lat=%f, lng=%f", 
                      northing, easting, latLng.latitude(), latLng.longitude());
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "latLngForProjectedMeters: Failed - %s", e.what());
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
}

napi_value NativeMapView::latLngForPixel(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "latLngForPixel() called");
    
    NapiArgs args(env, info);
    args.RequireMinArgs(2);
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    // 获取NativeMapView实例
    napi_value thisObj;
    napi_get_cb_info(env, info, nullptr, nullptr, &thisObj, nullptr);
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::error("NativeMapView", "latLngForPixel: Map not initialized");
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    double x = args.GetDouble(0, "x");
    double y = args.GetDouble(1, "y");
    if (args.HasError()) {
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
    
    try {
        mbgl::LatLng latLng = instance->map->latLngForPixel(mbgl::ScreenCoordinate(x, y));
        napi_value result = LatLngHarmony::CreateLatLngObject(env, latLng);
        Logger::debug("NativeMapView", "latLngForPixel: x=%f, y=%f -> lat=%f, lng=%f", 
                      x, y, latLng.latitude(), latLng.longitude());
        return result;
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "latLngForPixel: Failed - %s", e.what());
        napi_value undefined;
        napi_get_undefined(env, &undefined);
        return undefined;
    }
}

napi_value NativeMapView::latLngsForPixels(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "latLngsForPixels() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现数组参数解析和结果数组返回
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:802-826
    Logger::warn("NativeMapView", "latLngsForPixels: Not implemented - requires array parameter parsing");
    
    return undefined;
}

napi_value NativeMapView::addPolylines(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "addPolylines() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Polyline 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/annotation/polyline.cpp
    Logger::warn("NativeMapView", "addPolylines: Not implemented - requires Polyline wrapper class");
    
    return undefined;
}

napi_value NativeMapView::addPolygons(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "addPolygons() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Polygon 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/annotation/polygon.cpp
    Logger::warn("NativeMapView", "addPolygons: Not implemented - requires Polygon wrapper class");
    
    return undefined;
}

napi_value NativeMapView::updatePolyline(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "updatePolyline() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Polyline 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:866-869
    Logger::warn("NativeMapView", "updatePolyline: Not implemented - requires Polyline wrapper class");
    
    return undefined;
}

napi_value NativeMapView::updatePolygon(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "updatePolygon() called");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // TODO: 需要实现 Polygon 的 NAPI 包装类
    // 参考 Android: platform/android/MapLibreAndroid/src/cpp/native_map_view.cpp:871-874
    Logger::warn("NativeMapView", "updatePolygon: Not implemented - requires Polygon wrapper class");
    
    return undefined;
}

napi_value NativeMapView::removeAnnotations(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== removeAnnotations() START ==========");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取 this 对象
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "removeAnnotations: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "removeAnnotations: Requires 1 argument (annotation IDs array)");
        return undefined;
    }
    
    // 获取 NativeMapView 实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "removeAnnotations: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "removeAnnotations: Map not initialized");
        return undefined;
    }
    
    // 检查参数是否是数组
    bool isArray = false;
    if (napi_is_array(env, args[0], &isArray) != napi_ok || !isArray) {
        Logger::error("NativeMapView", "removeAnnotations: First argument must be an array");
        return undefined;
    }
    
    // 获取数组长度
    uint32_t length = 0;
    if (napi_get_array_length(env, args[0], &length) != napi_ok) {
        Logger::error("NativeMapView", "removeAnnotations: Failed to get array length");
        return undefined;
    }
    
    Logger::info("NativeMapView", "removeAnnotations: Removing %u annotations", length);
    
    // 遍历 ID 数组并删除
    for (uint32_t i = 0; i < length; i++) {
        napi_value idValue;
        if (napi_get_element(env, args[0], i, &idValue) != napi_ok) {
            Logger::error("NativeMapView", "removeAnnotations: Failed to get ID at index %u", i);
            continue;
        }
        
        int64_t annotationId;
        if (napi_get_value_int64(env, idValue, &annotationId) != napi_ok) {
            Logger::error("NativeMapView", "removeAnnotations: Failed to parse ID at index %u", i);
            continue;
        }
        
        if (annotationId == -1) {
            continue; // 跳过无效 ID
        }
        
        try {
            instance->map->removeAnnotation(static_cast<mbgl::AnnotationID>(annotationId));
            Logger::debug("NativeMapView", "removeAnnotations[%u]: Removed annotation ID=%lld", i, annotationId);
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "removeAnnotations[%u]: Failed to remove ID=%lld - %s", i, annotationId, e.what());
        }
    }
    
    // 触发重绘
    if (length > 0) {
        try {
            instance->map->triggerRepaint();
            Logger::debug("NativeMapView", "removeAnnotations: Repaint triggered");
        } catch (const std::exception& e) {
            Logger::error("NativeMapView", "removeAnnotations: Failed to trigger repaint - %s", e.what());
        }
    }
    
    Logger::info("NativeMapView", "========== removeAnnotations() END ==========");
    return undefined;
}

napi_value NativeMapView::addAnnotationIcon(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== addAnnotationIcon() START ==========");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取 this 对象
    napi_value thisObj;
    size_t argc = 5;
    napi_value args[5];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "addAnnotationIcon: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 5) {
        Logger::error("NativeMapView", "addAnnotationIcon: Requires 5 arguments (symbol, width, height, scale, pixels)");
        return undefined;
    }
    
    // 获取 NativeMapView 实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "addAnnotationIcon: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "addAnnotationIcon: Map not initialized");
        return undefined;
    }
    
    // 解析参数：symbol (string), width, height, scale, pixels (Uint8Array)
    // 获取 symbol 字符串
    size_t symbolLength = 0;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &symbolLength);
    std::string symbol;
    if (symbolLength > 0) {
        symbol.resize(symbolLength);
        napi_get_value_string_utf8(env, args[0], &symbol[0], symbolLength + 1, &symbolLength);
    }
    
    // 获取尺寸和缩放比例
    int32_t width, height;
    double scale;
    if (napi_get_value_int32(env, args[1], &width) != napi_ok ||
        napi_get_value_int32(env, args[2], &height) != napi_ok ||
        napi_get_value_double(env, args[3], &scale) != napi_ok) {
        Logger::error("NativeMapView", "addAnnotationIcon: Failed to parse numeric arguments");
        return undefined;
    }
    
    // 获取 Uint8Array 像素数据
    void* pixelData = nullptr;
    size_t pixelLength = 0;
    napi_value arrayBuffer;
    
    // 尝试获取 TypedArray 的 ArrayBuffer
    if (napi_get_typedarray_info(env, args[4], nullptr, &pixelLength, &pixelData, &arrayBuffer, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "addAnnotationIcon: Failed to get pixel data");
        return undefined;
    }
    
    Logger::info("NativeMapView", "addAnnotationIcon: symbol=%s, width=%d, height=%d, scale=%f, pixelLength=%zu", 
                  symbol.c_str(), width, height, scale, pixelLength);
    
    try {
        // 创建图片数据
        mbgl::PremultipliedImage image({static_cast<uint32_t>(width), static_cast<uint32_t>(height)});
        
        // 复制像素数据
        size_t expectedSize = width * height * 4; // RGBA
        if (pixelLength >= expectedSize && pixelData) {
            std::memcpy(image.data.get(), pixelData, expectedSize);
            
            // 创建并添加图片到样式
            auto styleImage = std::make_unique<mbgl::style::Image>(
                symbol,
                std::move(image),
                static_cast<float>(scale)
            );
            
            instance->map->getStyle().addImage(std::move(styleImage));
            
            Logger::info("NativeMapView", "addAnnotationIcon: Icon '%s' added successfully", symbol.c_str());
        } else {
            Logger::error("NativeMapView", "addAnnotationIcon: Invalid pixel data size (expected %zu, got %zu)", 
                         expectedSize, pixelLength);
        }
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "addAnnotationIcon: Failed - %s", e.what());
    }
    
    Logger::info("NativeMapView", "========== addAnnotationIcon() END ==========");
    return undefined;
}

napi_value NativeMapView::removeAnnotationIcon(napi_env env, napi_callback_info info) {
    Logger::info("NativeMapView", "========== removeAnnotationIcon() START ==========");
    
    napi_value undefined;
    napi_get_undefined(env, &undefined);
    
    // 获取 this 对象
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok) {
        Logger::error("NativeMapView", "removeAnnotationIcon: Failed to get arguments");
        return undefined;
    }
    
    if (argc < 1) {
        Logger::error("NativeMapView", "removeAnnotationIcon: Requires 1 argument (symbol)");
        return undefined;
    }
    
    // 获取 NativeMapView 实例
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance) {
        Logger::error("NativeMapView", "removeAnnotationIcon: Failed to unwrap instance");
        return undefined;
    }
    
    if (!instance->map) {
        Logger::error("NativeMapView", "removeAnnotationIcon: Map not initialized");
        return undefined;
    }
    
    // 获取 symbol 字符串
    size_t symbolLength = 0;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &symbolLength);
    std::string symbol;
    if (symbolLength > 0) {
        symbol.resize(symbolLength);
        napi_get_value_string_utf8(env, args[0], &symbol[0], symbolLength + 1, &symbolLength);
    }
    
    Logger::info("NativeMapView", "removeAnnotationIcon: symbol=%s", symbol.c_str());
    
    try {
        instance->map->getStyle().removeImage(symbol);
        Logger::info("NativeMapView", "removeAnnotationIcon: Icon '%s' removed successfully", symbol.c_str());
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "removeAnnotationIcon: Failed - %s", e.what());
    }
    
    Logger::info("NativeMapView", "========== removeAnnotationIcon() END ==========");
    return undefined;
}

napi_value NativeMapView::getTopOffsetPixelsForAnnotationSymbol(napi_env env, napi_callback_info info) {
    Logger::debug("NativeMapView", "getTopOffsetPixelsForAnnotationSymbol() called");
    
    napi_value result;
    napi_create_double(env, 0.0, &result);
    
    // 获取NativeMapView实例和参数
    napi_value thisObj;
    size_t argc = 1;
    napi_value args[1];
    if (napi_get_cb_info(env, info, &argc, args, &thisObj, nullptr) != napi_ok || argc < 1) {
        Logger::warn("NativeMapView", "getTopOffsetPixelsForAnnotationSymbol: Missing symbol name argument, returning 0.0");
        return result;
    }
    
    NativeMapView* instance = nullptr;
    if (napi_unwrap(env, thisObj, reinterpret_cast<void**>(&instance)) != napi_ok || !instance->map) {
        Logger::warn("NativeMapView", "getTopOffsetPixelsForAnnotationSymbol: Map not initialized, returning 0.0");
        return result;
    }
    
    // 获取 symbol 名称
    size_t symbolLength = 0;
    napi_get_value_string_utf8(env, args[0], nullptr, 0, &symbolLength);
    std::string symbolName(symbolLength, '\0');
    napi_get_value_string_utf8(env, args[0], &symbolName[0], symbolLength + 1, &symbolLength);
    symbolName.resize(symbolLength);
    
    try {
        double offset = instance->map->getTopOffsetPixelsForAnnotationImage(symbolName);
        napi_create_double(env, offset, &result);
        Logger::debug("NativeMapView", "getTopOffsetPixelsForAnnotationSymbol: symbol=%s, offset=%f", symbolName.c_str(), offset);
    } catch (const std::exception& e) {
        Logger::error("NativeMapView", "getTopOffsetPixelsForAnnotationSymbol: Failed - %s", e.what());
    }
    
    return result;
}


} // namespace harmony
} // namespace mbgl
