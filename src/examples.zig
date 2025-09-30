const c = @cImport({
    @cDefine("GL_GLEXT_PROTOTYPES", "");
    @cInclude("GL/gl.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const Zepr = @import("Zepr.zig");

const vertex_shader =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\
    \\void main()
    \\{
    \\    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\}
;

const fragment_shader =
    \\#version 330 core
    \\out vec4 FragColor;
    \\void main()
    \\{
    \\    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\}
;

const FillType = enum { None, Fill };

pub const Triangle = struct {
    program: Zepr,
    VBO: u32 = undefined,
    VAO: u32 = undefined,
    fill: FillType = .None,

    pub fn init(fill: FillType) !Triangle {
        var prog = Zepr.create("triangle");
        try prog.addVertexShader(vertex_shader);
        try prog.addFragmentShader(fragment_shader);
        try prog.compile();

        const vertices = [_]f32{
            -0.5, -0.5, 0.0,
            0.5,  -0.5, 0.0,
            0.0,  0.5,  0.0,
        };
        var vao: u32 = undefined;
        var vbo: u32 = undefined;

        c.glGenVertexArrays(1, &vao);
        c.glGenBuffers(1, &vbo);
        c.glBindVertexArray(vao);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);
        // position attr
        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
        c.glEnableVertexAttribArray(0);
        c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
        c.glBindVertexArray(0);

        return Triangle{ .program = prog, .VAO = vao, .VBO = vbo, .fill = fill };
    }

    pub fn draw(triangle: *Triangle) !void {
        c.glUseProgram(triangle.program.id);

        c.glPolygonMode(
            c.GL_FRONT_AND_BACK,
            switch (triangle.fill) {
                .Fill => c.GL_FILL,
                .None => c.GL_LINE,
            },
        );
        c.glBindVertexArray(triangle.VAO);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    }

    pub fn deinit(triangle: *Triangle) void {
        c.glDeleteVertexArrays(1, &triangle.VAO);
        c.glDeleteBuffers(1, &triangle.VBO);
        triangle.program.destroy();
        std.log.debug("[TRI]: Destroyed", .{});
    }
};

pub const Rectangle = struct {
    program: Zepr,
    VBO: u32 = undefined,
    VAO: u32 = undefined,
    EBO: u32 = undefined,
    fill: FillType = .None,

    pub fn init(fill: FillType) !Rectangle {
        var prog = Zepr.create("rectangle");
        try prog.addVertexShader(vertex_shader);
        try prog.addFragmentShader(fragment_shader);
        try prog.compile();

        const vertices = [_]f32{
            0.5, 0.5, 0.0, // top right
            0.5, -0.5, 0.0, // bottom right
            -0.5, -0.5, 0.0, // bottom let
            -0.5, 0.5, 0.0, // top let
        };
        const indices = [_]u32{
            // note that we start from 0!
            0, 1, 3, // first triangle
            1, 2, 3, // second triangle
        };

        var vao: u32 = undefined;
        var vbo: u32 = undefined;
        var ebo: u32 = undefined;

        c.glGenVertexArrays(1, &vao);
        c.glGenBuffers(1, &vbo);
        c.glGenBuffers(1, &ebo);

        c.glBindVertexArray(vao);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
        c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, c.GL_STATIC_DRAW);

        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
        c.glEnableVertexAttribArray(0);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
        // c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, 0);
        c.glBindVertexArray(0);

        return Rectangle{ .program = prog, .VAO = vao, .VBO = vbo, .EBO = ebo, .fill = fill };
    }

    pub fn draw(rectangle: *Rectangle) !void {
        c.glUseProgram(rectangle.program.id);
        c.glPolygonMode(
            c.GL_FRONT_AND_BACK,
            switch (rectangle.fill) {
                .Fill => c.GL_FILL,
                .None => c.GL_LINE,
            },
        );
        c.glBindVertexArray(rectangle.VAO);
        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
        c.glBindVertexArray(0);
    }

    pub fn deinit(rectangle: *Rectangle) void {
        c.glDeleteVertexArrays(1, &rectangle.VAO);
        c.glDeleteBuffers(1, &rectangle.VBO);
        c.glDeleteBuffers(1, &rectangle.EBO);
        rectangle.program.destroy();
        std.log.debug("[RECT]: Destroyed", .{});
    }
};
