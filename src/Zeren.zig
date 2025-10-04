///! This is a doc comment??
const std = @import("std");
const c = @cImport({
    @cDefine("GL_GLEXT_PROTOTYPES", "");
    @cInclude("GL/gl.h");
    @cInclude("GLFW/glfw3.h");
});
const log = std.log;

pub fn init() !void {
    log.debug("Initializing renderer", .{});
    if (c.glfwInit() == 0) return error.ZInitErr;
}

pub fn deinit() void {
    log.debug("Deinitializing renderer", .{});
    c.glfwTerminate();
}

pub fn setClearColor(color: Color) void {
    const glc = color.toGL();
    c.glClearColor(glc.r, glc.g, glc.b, glc.a);
}

pub fn setColor(color: Color) void {
    const glc = color.toGL();
    c.glColor4f(glc.r, glc.g, glc.b, glc.a);
}

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn toGL(color: Color) struct { r: f32, g: f32, b: f32, a: f32 } {
        return .{
            .r = @as(f32, @floatFromInt(color.r)) / 255.0,
            .g = @as(f32, @floatFromInt(color.g)) / 255.0,
            .b = @as(f32, @floatFromInt(color.b)) / 255.0,
            .a = @as(f32, @floatFromInt(color.a)) / 255.0,
        };
    }
};

pub const Keys = struct {
    pub const ESCAPE = c.GLFW_KEY_ESCAPE;
    pub const ENTER = c.GLFW_KEY_ENTER;
    pub const SPACE = c.GLFW_KEY_SPACE;
    pub const UP = c.GLFW_KEY_UP;
    pub const DOWN = c.GLFW_KEY_DOWN;
    pub const LEFT = c.GLFW_KEY_LEFT;
    pub const RIGHT = c.GLFW_KEY_RIGHT;
    pub const W = c.GLFW_KEY_W;
    pub const A = c.GLFW_KEY_A;
    pub const S = c.GLFW_KEY_S;
    pub const D = c.GLFW_KEY_D;
    pub const Q = c.GLFW_KEY_Q;
};

fn frameBufferSizeCallback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.c) void {
    _ = window;
    c.glViewport(0, 0, width, height);
}

const WindowOptions = struct {
    bg_color: ?Color,
    fullscreen: bool = false,
};

pub const Window = struct {
    handle: *c.struct_GLFWwindow,

    pub fn createWindow(w: i32, h: i32, title: []const u8, opts: WindowOptions) !Window {
        log.debug("Creating Window", .{});
        const window = c.glfwCreateWindow(@intCast(w), @intCast(h), @ptrCast(title.ptr), if (opts.fullscreen) c.glfwGetPrimaryMonitor() else null, null);
        if (window == null) return error.ZWindowCreationErr;
        c.glfwMakeContextCurrent(window);
        const clear_color = if (opts.bg_color != null) opts.bg_color.? else Color{ .r = 24, .g = 24, .b = 24, .a = 255 };
        setClearColor(clear_color);

        c.glViewport(0, 0, @intCast(w), @intCast(h));
        _ = c.glfwSetFramebufferSizeCallback(window, frameBufferSizeCallback);
        return Window{ .handle = window.? };
    }

    pub fn destroy(window: *Window) void {
        log.debug("Destroying Window", .{});
        c.glfwDestroyWindow(window.handle);
    }

    pub fn isKeyDown(window: *Window, key: i32) bool {
        return c.glfwGetKey(window.handle, key) == 1;
    }

    pub fn closeWindowEvt(window: *Window) bool {
        return window.isCtrlDown() and window.isKeyDown(Keys.Q);
    }

    pub fn isCtrlDown(window: *Window) bool {
        return isKeyDown(window, c.GLFW_KEY_LEFT_CONTROL) or
            isKeyDown(window, c.GLFW_KEY_RIGHT_CONTROL);
    }

    pub fn shouldClose(window: *Window) bool {
        return c.glfwWindowShouldClose(window.handle) == c.GL_TRUE;
    }

    pub fn beginFrame(window: *Window) void {
        _ = window;
        c.glClear(c.GL_COLOR_BUFFER_BIT);
    }

    pub fn endFrame(self: *Window) void {
        c.glfwSwapBuffers(self.handle);
        c.glfwSwapInterval(1);
        c.glfwPollEvents();
    }
};

const Zeren = @This();
