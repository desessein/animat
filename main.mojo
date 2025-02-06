import wgpu
from wgpu import (
    glfw,
)
from sys.info import sizeof

from memory import Span, UnsafePointer, ArcPointer
from collections import Optional


@value
struct Vec3:
    var x: Float32
    var y: Float32
    var z: Float32


@value
struct MyColor:
    var r: Float32
    var g: Float32
    var b: Float32
    var a: Float32


@value
struct MyVertex:
    var pos: Vec3
    var color: MyColor


def main():
    glfw.init()
    glfw.window_hint(glfw.CLIENT_API, glfw.NO_API)
    window = glfw.Window(640, 480, "Hello, WebGPU")

    while not window.should_close():
        glfw.poll_events()

    glfw.terminate()
