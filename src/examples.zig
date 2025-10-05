const c = @cImport({
    @cDefine("GL_GLEXT_PROTOTYPES", "");
    @cInclude("GL/gl.h");
    @cInclude("GLFW/glfw3.h");
});
const std = @import("std");
const Zepr = @import("Zepr.zig");

const FillType = enum { None, Fill };

pub const Triangle = struct {
    program: Zepr,
    VBO: u32 = undefined,
    VAO: u32 = undefined,
    fill: FillType = .None,

    pub fn init(allocator: std.mem.Allocator, fill: FillType) !Triangle {
        var prog = Zepr.create(allocator, "triangle");
        try prog.loadVertexShaderFromFile("./shaders/basic-tringle-vt.glsl");
        try prog.loadFragmentShaderFromFile("./shaders/basic-frag.glsl");
        try prog.compile();

        const vertices = [_]f32{
            -0.9, 0.9, 0.0,
            -0.8, 0.7, 0.0,
            -1.0, 0.7, 0.0,
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

    pub fn init(allocator: std.mem.Allocator, fill: FillType) !Rectangle {
        var prog = Zepr.create(allocator, "rectangle");
        try prog.loadVertexShaderFromFile("./shaders/basic-tringle-vt.glsl");
        try prog.loadFragmentShaderFromFile("./shaders/basic-frag.glsl");
        try prog.compile();

        const vertices = [_]f32{
            -0.55, 0.9, 0.0,
            -0.55, 0.7, 0.0,
            -0.75, 0.7, 0.0,
            -0.75, 0.9, 0.0,
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

pub const PulsingTriangle = struct {
    program: Zepr,
    VBO: u32 = undefined,
    VAO: u32 = undefined,
    fill: FillType = .None,

    pub fn init(allocator: std.mem.Allocator, fill: FillType) !PulsingTriangle {
        const vertex_shader_src: []const u8 =
            \\#version 330 core
            \\layout (location = 0) in vec3 aPos;
            \\void main()
            \\{
            \\   gl_Position = vec4(aPos, 1.0);
            \\}
        ;
        const frag_shader_src: []const u8 =
            \\#version 330 core
            \\out vec4 FragColor;
            \\uniform vec4 ourColor;
            \\void main()
            \\{
            \\   FragColor = ourColor;
            \\}
        ;
        var prog = Zepr.create(allocator, "cc-tri");
        try prog.addVertexShader(vertex_shader_src);
        try prog.addFragmentShader(frag_shader_src);
        try prog.compile();

        const vertices = [_]f32{
            -0.4, 0.9, 0.0,
            -0.3, 0.7, 0.0,
            -0.5, 0.7, 0.0,
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

        return PulsingTriangle{ .program = prog, .VAO = vao, .VBO = vbo, .fill = fill };
    }

    pub fn draw(triangle: *PulsingTriangle) !void {
        c.glUseProgram(triangle.program.id);

        c.glPolygonMode(
            c.GL_FRONT_AND_BACK,
            switch (triangle.fill) {
                .Fill => c.GL_FILL,
                .None => c.GL_LINE,
            },
        );

        const time = c.glfwGetTime();
        const green_val: f32 = @floatCast(@sin(time) / 2.0 + 0.5);

        const vertex_color_location = c.glGetUniformLocation(triangle.program.id, "ourColor");
        c.glUniform4f(vertex_color_location, 0.0, green_val, 0.0, 1.0);
        c.glBindVertexArray(triangle.VAO);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    }

    pub fn deinit(triangle: *PulsingTriangle) void {
        c.glDeleteVertexArrays(1, &triangle.VAO);
        c.glDeleteBuffers(1, &triangle.VBO);
        triangle.program.destroy();
        std.log.debug("[PULSE-TRI]: Destroyed", .{});
    }
};

pub const RainbowTriangle = struct {
    program: Zepr,
    VBO: u32 = undefined,
    VAO: u32 = undefined,
    fill: FillType = .None,

    pub fn init(allocator: std.mem.Allocator, fill: FillType) !RainbowTriangle {
        const vertex_shader_src: []const u8 =
            \\#version 330 core
            \\layout (location = 0) in vec3 aPos;
            \\layout (location = 1) in vec3 aColor;
            \\out vec3 rbColor;
            \\void main()
            \\{
            \\   gl_Position = vec4(aPos, 1.0);
            \\   rbColor = aColor;
            \\}
        ;
        const frag_shader_src: []const u8 =
            \\#version 330 core
            \\out vec4 FragColor;
            \\in vec3 rbColor;
            \\void main()
            \\{
            \\   FragColor = vec4(rbColor, 1.0f);
            \\}
        ;
        var prog = Zepr.create(allocator, "rb-tri");
        try prog.addVertexShader(vertex_shader_src);
        try prog.addFragmentShader(frag_shader_src);
        try prog.compile();

        const vertices = [_]f32{
            // positions    // colors
            -0.15, 0.9, 0.0, 1.0, 0.0, 0.0, // bottom right
            -0.05, 0.7, 0.0, 0.0, 1.0, 0.0, // bottom left
            -0.25, 0.7, 0.0, 0.0, 0.0, 1.0, // top
        };
        var vao: u32 = undefined;
        var vbo: u32 = undefined;

        c.glGenVertexArrays(1, &vao);
        c.glGenBuffers(1, &vbo);
        c.glBindVertexArray(vao);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);
        // position attr
        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), null);
        c.glEnableVertexAttribArray(0);

        // color attr
        // the `pointer` is used as an offset
        // const p = 3*@sizeOf(f32);
        // c.glVertexAttribPointer(..., @ptrCast(&p));
        // is very wrong as it hands gl the address, but instead it needs
        // the int value but represented as a pointer
        c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
        c.glEnableVertexAttribArray(1);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);

        return RainbowTriangle{ .program = prog, .VAO = vao, .VBO = vbo, .fill = fill };
    }

    pub fn draw(triangle: *RainbowTriangle) !void {
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

    pub fn deinit(triangle: *RainbowTriangle) void {
        c.glDeleteVertexArrays(1, &triangle.VAO);
        c.glDeleteBuffers(1, &triangle.VBO);
        triangle.program.destroy();
        std.log.debug("[RAINBOW-TRI]: Destroyed", .{});
    }
};
