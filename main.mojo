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
    WaveInterferenceAnimation
)
from sys.info import sizeof

from memory import Span, UnsafePointer, ArcPointer
from collections import Optional

def main():
    glfw.init()
    glfw.window_hint(glfw.CLIENT_API, glfw.NO_API)
    window = glfw.Window(640, 1080, "Hello, WebGPU")

    animation = WaveInterferenceAnimation()
    renderer = Renderer[WaveInterferenceAnimation](window, animation)

    u_time = Float32(0)
    while not window.should_close():
        x, y = window.get_cursor_pos()
        print(y)
        glfw.poll_events()
        u_time = renderer.render(u_time, Float32(x))
    
    glfw.terminate()