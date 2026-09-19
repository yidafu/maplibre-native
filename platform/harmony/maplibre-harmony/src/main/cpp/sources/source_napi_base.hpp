#ifndef MAPLIBRE_HARMONY_SOURCE_NAPI_BASE_HPP
#define MAPLIBRE_HARMONY_SOURCE_NAPI_BASE_HPP

// Shared CRTP base for the per-source-type NAPI wrappers.
//
// All seven wrappers (GeoJSON, Image, Video, Raster, RasterDEM, Vector,
// CustomGeometry) used to carry a byte-identical copy of the same ownership
// state and the same four accessors, differing only in the core source type.
// Conceptually they are one thing: "a JS wrapper around an mln::style::XSource
// that either owns it (until Style::addSource takes over) or reaches it through
// a WeakPtr". That concept lives here once.
//
// Each wrapper keeps its own static NAPI plumbing (Init / New / CreateInstance
// / constructor / constructorEnv) - that part is genuinely per-class.
//
// GeoJsonSourceNAPI is the one exception: it re-declares getSource() and
// attachToStyle() to keep its extra diagnostics for a failed WeakPtr
// initialisation. Those override by hiding (non-virtual members, never called
// through a base pointer), and their return semantics are identical.

#include <mln/style/source.hpp>

#include <memory>
#include <string>

namespace mln {
namespace harmony {

/**
 * Ownership + WeakPtr state shared by every source NAPI wrapper.
 *
 * @tparam Derived the wrapper class (CRTP)
 * @tparam SourceT the concrete `mln::style::XSource` being wrapped
 */
template <typename Derived, typename SourceT>
class SourceNapiBase {
public:
    SourceNapiBase(const std::string& sourceId, std::unique_ptr<SourceT> src)
        : id(sourceId), source(std::move(src)), ownsSource(true) {}

    /**
     * Adopt a source already owned by the style. Only a WeakPtr is kept: once
     * the source leaves the style, a raw pointer would dangle.
     */
    explicit SourceNapiBase(SourceT* sourcePtr) : ownsSource(false) {
        if (sourcePtr) {
            id = sourcePtr->getID();
            weakSource = sourcePtr->makeWeakPtr();
        }
    }

    /** The wrapped core source, or nullptr once it is gone. */
    SourceT* getSource() const {
        if (!source && weakSource) {
            return static_cast<SourceT*>(weakSource.get());
        }
        return source.get();
    }

    std::string getId() const { return id; }

    /** Hand ownership to Style::addSource; arm the WeakPtr via attachToStyle(). */
    std::unique_ptr<mln::style::Source> releaseSource() {
        ownsSource = false;
        return std::move(source);
    }

    /** Re-arm the WeakPtr after ownership moved to the style. */
    void attachToStyle(SourceT* sourcePtr) {
        if (sourcePtr) {
            weakSource = sourcePtr->makeWeakPtr();
        }
    }

protected:
    // Non-virtual and protected on purpose: instances are only ever deleted
    // through their concrete type (the napi Destructor callbacks), so a
    // delete-through-base would be a bug the compiler should reject.
    ~SourceNapiBase() = default;

    std::string id;
    std::unique_ptr<SourceT> source;
    bool ownsSource;
    mapbox::base::WeakPtr<mln::style::Source> weakSource;
};

} // namespace harmony
} // namespace mln

#endif // MAPLIBRE_HARMONY_SOURCE_NAPI_BASE_HPP
