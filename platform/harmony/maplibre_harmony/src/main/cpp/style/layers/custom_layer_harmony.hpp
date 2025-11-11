#pragma once

#include <mbgl/style/layers/custom_layer.hpp>
#include <mbgl/style/layers/custom_layer_render_parameters.hpp>
#include <GLES3/gl3.h>
#include <memory>
#include <mutex>

namespace mbgl {
namespace harmony {

/**
 * ExampleCustomLayerHost - sample custom layer implementation.
 *
 * Demonstrates how to use OpenGL ES 3.0 to render custom content onto the map.
 *
 * This implementation draws a color-filled quad covering the entire viewport and
 * allows the color to be adjusted dynamically.
 */
class ExampleCustomLayerHost : public mbgl::style::CustomLayerHost {
public:
    ExampleCustomLayerHost();
    ~ExampleCustomLayerHost() override;

    // CustomLayerHost interface implementation
    void initialize() override;
    void render(const mbgl::style::CustomLayerRenderParameters& parameters) override;
    void contextLost() override;
    void deinitialize() override;

    // Helper utilities
    /**
     * Set the render color.
     * @param r Red component (0.0 - 1.0)
     * @param g Green component (0.0 - 1.0)
     * @param b Blue component (0.0 - 1.0)
     * @param a Alpha component (0.0 - 1.0)
     */
    void setColor(float r, float g, float b, float a);

    /**
     * Retrieve the current color.
     * @param outColor Output color array [r, g, b, a]
     */
    void getColor(float outColor[4]) const;

private:
    /**
     * Check for OpenGL errors.
     * @param operation Description of the operation just performed
     * @return true if an error occurred
     */
    bool checkGLError(const char* operation);

    /**
     * Create the shader program.
     * @return Program ID on success, 0 on failure
     */
    GLuint createShaderProgram();

    /**
     * Compile a shader.
     * @param type Shader type (GL_VERTEX_SHADER or GL_FRAGMENT_SHADER)
     * @param source Shader source code
     * @return Shader ID on success, 0 on failure
     */
    GLuint compileShader(GLenum type, const char* source);

    /**
     * Link the shader program.
     * @param program Program ID
     * @return true on success
     */
    bool linkProgram(GLuint program);

    // OpenGL resources
    GLuint program_;           // Shader program
    GLuint vertexShader_;      // Vertex shader
    GLuint fragmentShader_;    // Fragment shader
    GLuint buffer_;            // Vertex buffer object
    GLint positionAttrib_;     // Attribute location for position
    GLint colorUniform_;       // Uniform location for color

    // Render state
    float color_[4];           // Current color [r, g, b, a]
    mutable std::mutex mutex_; // Protects color state
    bool initialized_;         // Initialization flag

    // Shader sources
    static const char* vertexShaderSource_;
    static const char* fragmentShaderSource_;
};

} // namespace harmony
} // namespace mbgl

