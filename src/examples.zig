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

pub const Triangle = struct {
    program: Zepr,
    VBO: u32 = undefined,
    VAO: u32 = undefined,

    pub fn init(outline: bool) !Triangle {
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

        if (outline) {
            std.log.info("Drawing with outline mode", .{});
            c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);
        }

        return Triangle{
            .program = prog,
            .VAO = vao,
            .VBO = vbo,
        };
    }

    pub fn draw(triangle: *Triangle) !void {
        c.glUseProgram(triangle.program.id);
        c.glBindVertexArray(triangle.VAO);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
    }

    pub fn deinit(triangle: *Triangle) void {
        _ = triangle;
    }
};
