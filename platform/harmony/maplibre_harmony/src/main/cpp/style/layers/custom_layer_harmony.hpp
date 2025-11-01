#pragma once

#include <mbgl/style/layers/custom_layer.hpp>
#include <mbgl/style/layers/custom_layer_render_parameters.hpp>
#include <GLES3/gl3.h>
#include <memory>
#include <mutex>

namespace mbgl {
namespace harmony {

/**
 * ExampleCustomLayerHost - 示例自定义图层实现
 * 
 * 这是一个简单的 CustomLayerHost 实现，用于演示如何使用 OpenGL ES 3.0
 * 渲染自定义内容到地图上。
 * 
 * 该实现渲染一个填充整个视口的彩色矩形，颜色可以动态修改。
 */
class ExampleCustomLayerHost : public mbgl::style::CustomLayerHost {
public:
    ExampleCustomLayerHost();
    ~ExampleCustomLayerHost() override;

    // CustomLayerHost 接口实现
    void initialize() override;
    void render(const mbgl::style::CustomLayerRenderParameters& parameters) override;
    void contextLost() override;
    void deinitialize() override;

    // 辅助方法
    /**
     * 设置渲染颜色
     * @param r 红色分量 (0.0 - 1.0)
     * @param g 绿色分量 (0.0 - 1.0)
     * @param b 蓝色分量 (0.0 - 1.0)
     * @param a 透明度 (0.0 - 1.0)
     */
    void setColor(float r, float g, float b, float a);

    /**
     * 获取当前颜色
     * @param outColor 输出颜色数组 [r, g, b, a]
     */
    void getColor(float outColor[4]) const;

private:
    /**
     * 检查 OpenGL 错误
     * @param operation 操作描述
     * @return true 如果有错误
     */
    bool checkGLError(const char* operation);

    /**
     * 创建着色器程序
     * @return 成功返回程序ID，失败返回0
     */
    GLuint createShaderProgram();

    /**
     * 编译着色器
     * @param type 着色器类型 (GL_VERTEX_SHADER 或 GL_FRAGMENT_SHADER)
     * @param source 着色器源码
     * @return 成功返回着色器ID，失败返回0
     */
    GLuint compileShader(GLenum type, const char* source);

    /**
     * 链接着色器程序
     * @param program 程序ID
     * @return 成功返回true
     */
    bool linkProgram(GLuint program);

    // OpenGL 资源
    GLuint program_;           // 着色器程序
    GLuint vertexShader_;      // 顶点着色器
    GLuint fragmentShader_;    // 片段着色器
    GLuint buffer_;            // 顶点缓冲对象
    GLint positionAttrib_;     // 位置属性位置
    GLint colorUniform_;       // 颜色uniform位置

    // 渲染状态
    float color_[4];           // 当前颜色 [r, g, b, a]
    mutable std::mutex mutex_; // 保护颜色状态的互斥锁
    bool initialized_;         // 是否已初始化

    // 着色器源码
    static const char* vertexShaderSource_;
    static const char* fragmentShaderSource_;
};

} // namespace harmony
} // namespace mbgl

