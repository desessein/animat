from sys import ffi
from collections.string import StringSlice
from memory import UnsafePointer, Span

# Core GLFW library handle
var _glfw = ffi.DLHandle("libglfw.so.3", ffi.RTLD.LAZY)

# Constants
alias CLIENT_API = 0x00022001
alias NO_API = 0


# Forward declarations for GLFW types
struct _GLFWwindow:
    pass


struct _GLFWmonitor:
    pass


# Platform identification
@value
struct Platform:
    var value: Int32

    @implicit
    fn __init__(out self, value: Int32):
        self.value = value

    # Platform constants
    alias win32 = Self(0x00060001)
    alias cocoa = Self(0x00060002)
    alias wayland = Self(0x00060003)
    alias x11 = Self(0x00060004)
    alias null = Self(0x00060005)

    fn __eq__(self, rhs: Self) -> Bool:
        return self.value == rhs.value

    fn __ne__(self, rhs: Self) -> Bool:
        return self.value != rhs.value


# Core function pointers
var _window_should_close = _glfw.get_function[
    fn (UnsafePointer[_GLFWwindow]) -> Bool
]("glfwWindowShouldClose")

var _poll_events = _glfw.get_function[fn () -> None]("glfwPollEvents")

var _window_hint = _glfw.get_function[fn (Int32, Int32) -> None](
    "glfwWindowHint"
)


# Public API functions
fn init():
    _glfw.get_function[fn () -> None]("glfwInit")()


fn terminate():
    _glfw.get_function[fn () -> None]("glfwTerminate")()


fn poll_events():
    _poll_events()


fn window_hint(hint: Int32, value: Int32):
    _window_hint(hint, value)


fn get_platform() -> Platform:
    """Returns the currently selected platform."""
    return _glfw.get_function[fn () -> Int32]("glfwGetPlatform")()


# Window management
struct Window:
    var _handle: UnsafePointer[_GLFWwindow]
    var title: String

    fn __init__(out self, width: Int32, height: Int32, owned title: String):
        self.title = title
        self._handle = _glfw.get_function[
            fn (
                Int32,
                Int32,
                UnsafePointer[Int8],
                UnsafePointer[_GLFWmonitor],
                UnsafePointer[_GLFWwindow],
            ) -> UnsafePointer[_GLFWwindow]
        ]("glfwCreateWindow")(
            width,
            height,
            self.title.unsafe_cstr_ptr(),
            UnsafePointer[_GLFWmonitor](),
            UnsafePointer[_GLFWwindow](),
        )

    fn should_close(self) -> Bool:
        return _window_should_close(self._handle)

    fn __del__(owned self):
        _glfw.get_function[fn (UnsafePointer[_GLFWwindow]) -> None](
            "glfwDestroyWindow"
        )(self._handle)

    fn get_x11_display(self) -> UnsafePointer[NoneType]:
        return _glfw.get_function[
            fn (UnsafePointer[_GLFWwindow]) -> UnsafePointer[NoneType]
        ]("glfwGetX11Display")(self._handle)

    fn get_x11_window(self) -> Int:
        return _glfw.get_function[fn (UnsafePointer[_GLFWwindow]) -> Int](
            "glfwGetX11Window"
        )(self._handle)

    fn get_cursor_pos(self) -> (Float64, Float64):
        var x_pointer: Float64 = 0.0
        var y_pointer: Float64 = 0.0

        _glfw.get_function[
            fn (
                UnsafePointer[_GLFWwindow], 
                UnsafePointer[Float64], 
                UnsafePointer[Float64]
            ) -> None
        ]("glfwGetCursorPos")(
            self._handle, 
            UnsafePointer[Float64].address_of(x_pointer), 
            UnsafePointer[Float64].address_of(y_pointer)
            )
        
        return (x_pointer, y_pointer)
