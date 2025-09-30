const c = @cImport({
    @cDefine("GL_GLEXT_PROTOTYPES", "");
    @cInclude("GL/gl.h");
});

const std = @import("std");
const Zepr = @import("Zepr.zig");
const log = std.log;

allocator: std.mem.Allocator,
elements: std.ArrayList(UiElement) = .empty,

const UiElement = struct {
    name: []const u8,
    draw: *const fn () void,
};

pub fn init(allocator: std.mem.Allocator) Zerui {
    return Zerui{ .allocator = allocator };
}

pub fn deinit(zerui: *Zerui) void {
    _ = zerui;
}

pub fn draw(zerui: *Zerui) !void {
    _ = zerui;
}

pub fn addElement(zerui: *Zerui, elem: UiElement) void {
    _ = zerui;
    _ = elem;
}

const VertexType = enum { Rounded, Sharp };
pub const Button = struct {
    option: VertexType = .Sharp,
    program: c.GLuint,

    pub fn init(button_type: VertexType) !Button {

        // button will need some random id at the end
        // to ensure they dont collide and stuff maybe??
        // will think more about this
        const button_type_str = switch (button_type) {
            .Rounded => "rounded_btn",
            .Sharp => "not_rounded_btn",
        };

        var shb = Zepr.create(button_type_str);
        try shb.addVertexShader(
            \\#version 330 core
            \\layout (location = 0) in vec3 aPos;
            \\
            \\void main() {
            \\    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
            \\}
        );
        try shb.addFragmentShader(
            \\#version 330 core
            \\out vec4 FragColor;
            \\
            \\void main() {
            \\    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
            \\}
        );
        try shb.compile();
        return Button{ .option = button_type, .program = shb.id };
    }

    pub fn draw(zerui: *Button) void {
        c.glUseProgram(zerui.program);
    }
};

const Zerui = @This();
