import wgpu
from wgpu import (
    Renderer,
    glfw,
    SurfaceConfiguration,
    VertexAttribute,
    VertexFormat,
    Color,
    VertexBufferLayout,
    BufferUsage,
    BufferDescriptor,
    VertexStepMode,
    TextureFormat,
    PipelineLayout,
    BindGroupLayout,
    BufferBindingLayout,
    BindGroupLayoutEntry,
    BindGroupDescriptor,
    BindGroupLayoutDescriptor,
    PipelineLayoutDescriptor,
    BindGroupEntry,
    BufferBinding,
    KaleidoscopeAnimation,
)
from sys.info import sizeof

from memory import Span, UnsafePointer, ArcPointer
from collections import Optional

def main():
    glfw.init()
    glfw.window_hint(glfw.CLIENT_API, glfw.NO_API)
    window = glfw.Window(640, 480, "Hello, WebGPU")

    animation = KaleidoscopeAnimation()
    renderer = Renderer[KaleidoscopeAnimation](window, animation)

    u_time = Float32(0)
    while not window.should_close():
        glfw.poll_events()
        u_time = renderer.render(u_time)
    
    glfw.terminate()