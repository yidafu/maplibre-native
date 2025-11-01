#include "custom_layer_harmony.hpp"
#include "utils/logger.h"
#include <sstream>
#include <vector>

using mbgl::harmony::Logger;

namespace mbgl {
namespace harmony {

// 顶点着色器源码 - OpenGL ES 3.0
const char* ExampleCustomLayerHost::vertexShaderSource_ = R"(
#version 300 es
layout (location = 0) in vec2 a_pos;
void main() {
    gl_Position = vec4(a_pos, 0.0, 1.0);
}
)";

// 片段着色器源码 - OpenGL ES 3.0
const char* ExampleCustomLayerHost::fragmentShaderSource_ = R"(
#version 300 es
precision highp float;
uniform vec4 u_color;
out vec4 fragColor;
void main() {
    fragColor = u_color;
}
)";

ExampleCustomLayerHost::ExampleCustomLayerHost()
    : program_(0)
    , vertexShader_(0)
    , fragmentShader_(0)
    , buffer_(0)
    , positionAttrib_(0)
    , colorUniform_(0)
    , initialized_(false) {
    // 默认颜色：绿色，半透明
    color_[0] = 0.0f;
    color_[1] = 1.0f;
    color_[2] = 0.0f;
    color_[3] = 0.5f;
    
    Logger::info("ExampleCustomLayerHost", "Constructor called");
}

ExampleCustomLayerHost::~ExampleCustomLayerHost() {
    Logger::info("ExampleCustomLayerHost", "Destructor called");
}

bool ExampleCustomLayerHost::checkGLError(const char* operation) {
    GLenum error = glGetError();
    if (error != GL_NO_ERROR) {
        const char* errorStr = "UNKNOWN";
        switch (error) {
            case GL_INVALID_ENUM: errorStr = "GL_INVALID_ENUM"; break;
            case GL_INVALID_VALUE: errorStr = "GL_INVALID_VALUE"; break;
            case GL_INVALID_OPERATION: errorStr = "GL_INVALID_OPERATION"; break;
            case GL_INVALID_FRAMEBUFFER_OPERATION: errorStr = "GL_INVALID_FRAMEBUFFER_OPERATION"; break;
            case GL_OUT_OF_MEMORY: errorStr = "GL_OUT_OF_MEMORY"; break;
        }
        Logger::error("ExampleCustomLayerHost", 
                     "OpenGL Error after %s: %s (0x%x)", 
                     operation, errorStr, error);
        return true;
    }
    return false;
}

GLuint ExampleCustomLayerHost::compileShader(GLenum type, const char* source) {
    GLuint shader = glCreateShader(type);
    if (shader == 0) {
        Logger::error("ExampleCustomLayerHost", "Failed to create shader");
        return 0;
    }

    glShaderSource(shader, 1, &source, nullptr);
    glCompileShader(shader);

    GLint compiled = 0;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    if (!compiled) {
        GLint infoLen = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
        if (infoLen > 0) {
            std::vector<char> infoLog(infoLen);
            glGetShaderInfoLog(shader, infoLen, nullptr, infoLog.data());
            Logger::error("ExampleCustomLayerHost", 
                         "Shader compilation failed: %s", infoLog.data());
        }
        glDeleteShader(shader);
        return 0;
    }

    return shader;
}

bool ExampleCustomLayerHost::linkProgram(GLuint program) {
    glLinkProgram(program);

    GLint linked = 0;
    glGetProgramiv(program, GL_LINK_STATUS, &linked);
    if (!linked) {
        GLint infoLen = 0;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLen);
        if (infoLen > 0) {
            std::vector<char> infoLog(infoLen);
            glGetProgramInfoLog(program, infoLen, nullptr, infoLog.data());
            Logger::error("ExampleCustomLayerHost", 
                         "Program linking failed: %s", infoLog.data());
        }
        return false;
    }

    return true;
}

GLuint ExampleCustomLayerHost::createShaderProgram() {
    // 编译顶点着色器
    vertexShader_ = compileShader(GL_VERTEX_SHADER, vertexShaderSource_);
    if (vertexShader_ == 0) {
        return 0;
    }

    // 编译片段着色器
    fragmentShader_ = compileShader(GL_FRAGMENT_SHADER, fragmentShaderSource_);
    if (fragmentShader_ == 0) {
        glDeleteShader(vertexShader_);
        vertexShader_ = 0;
        return 0;
    }

    // 创建程序
    GLuint program = glCreateProgram();
    if (program == 0) {
        Logger::error("ExampleCustomLayerHost", "Failed to create program");
        glDeleteShader(vertexShader_);
        glDeleteShader(fragmentShader_);
        vertexShader_ = 0;
        fragmentShader_ = 0;
        return 0;
    }

    // 附加着色器
    glAttachShader(program, vertexShader_);
    glAttachShader(program, fragmentShader_);

    // 链接程序
    if (!linkProgram(program)) {
        glDeleteProgram(program);
        glDeleteShader(vertexShader_);
        glDeleteShader(fragmentShader_);
        vertexShader_ = 0;
        fragmentShader_ = 0;
        return 0;
    }

    return program;
}

void ExampleCustomLayerHost::initialize() {
    Logger::info("ExampleCustomLayerHost", "Initialize");

    if (initialized_) {
        Logger::warn("ExampleCustomLayerHost", "Already initialized");
        return;
    }

    // 创建着色器程序
    program_ = createShaderProgram();
    if (program_ == 0) {
        Logger::error("ExampleCustomLayerHost", "Failed to create shader program");
        return;
    }

    // 获取属性和uniform位置
    positionAttrib_ = glGetAttribLocation(program_, "a_pos");
    colorUniform_ = glGetUniformLocation(program_, "u_color");

    Logger::info("ExampleCustomLayerHost", 
                "Position attrib: %d, Color uniform: %d", 
                positionAttrib_, colorUniform_);

    // 创建顶点缓冲 - 全屏矩形
    GLfloat vertices[] = {
        -1.0f, -1.0f,  // 左下
         1.0f, -1.0f,  // 右下
        -1.0f,  1.0f,  // 左上
         1.0f,  1.0f   // 右上
    };

    glGenBuffers(1, &buffer_);
    glBindBuffer(GL_ARRAY_BUFFER, buffer_);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    checkGLError("initialize");

    initialized_ = true;
    Logger::info("ExampleCustomLayerHost", "Initialize completed successfully");
}

void ExampleCustomLayerHost::render(const mbgl::style::CustomLayerRenderParameters& parameters) {
    if (!initialized_ || program_ == 0) {
        return;
    }

    // 使用着色器程序
    glUseProgram(program_);

    // 绑定顶点缓冲
    glBindBuffer(GL_ARRAY_BUFFER, buffer_);
    glEnableVertexAttribArray(positionAttrib_);
    glVertexAttribPointer(positionAttrib_, 2, GL_FLOAT, GL_FALSE, 0, nullptr);

    // 设置颜色uniform（线程安全）
    {
        std::lock_guard<std::mutex> lock(mutex_);
        glUniform4fv(colorUniform_, 1, color_);
    }

    // 禁用深度和模板测试
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_STENCIL_TEST);

    // 启用混合
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // 绘制
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    // 清理
    glDisableVertexAttribArray(positionAttrib_);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glUseProgram(0);

    checkGLError("render");
}

void ExampleCustomLayerHost::contextLost() {
    Logger::info("ExampleCustomLayerHost", "Context lost");
    
    // OpenGL 上下文丢失，重置所有句柄
    program_ = 0;
    vertexShader_ = 0;
    fragmentShader_ = 0;
    buffer_ = 0;
    initialized_ = false;
}

void ExampleCustomLayerHost::deinitialize() {
    Logger::info("ExampleCustomLayerHost", "Deinitialize");

    if (!initialized_) {
        return;
    }

    // 删除缓冲
    if (buffer_ != 0) {
        glDeleteBuffers(1, &buffer_);
        buffer_ = 0;
    }

    // 分离和删除着色器
    if (program_ != 0) {
        if (vertexShader_ != 0) {
            glDetachShader(program_, vertexShader_);
            glDeleteShader(vertexShader_);
            vertexShader_ = 0;
        }
        if (fragmentShader_ != 0) {
            glDetachShader(program_, fragmentShader_);
            glDeleteShader(fragmentShader_);
            fragmentShader_ = 0;
        }
        glDeleteProgram(program_);
        program_ = 0;
    }

    checkGLError("deinitialize");

    initialized_ = false;
    Logger::info("ExampleCustomLayerHost", "Deinitialize completed");
}

void ExampleCustomLayerHost::setColor(float r, float g, float b, float a) {
    std::lock_guard<std::mutex> lock(mutex_);
    color_[0] = r;
    color_[1] = g;
    color_[2] = b;
    color_[3] = a;
    Logger::info("ExampleCustomLayerHost", 
                "Color set to: %.2f, %.2f, %.2f, %.2f", r, g, b, a);
}

void ExampleCustomLayerHost::getColor(float outColor[4]) const {
    std::lock_guard<std::mutex> lock(mutex_);
    outColor[0] = color_[0];
    outColor[1] = color_[1];
    outColor[2] = color_[2];
    outColor[3] = color_[3];
}

} // namespace harmony
} // namespace mbgl

