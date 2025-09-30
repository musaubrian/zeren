const c = @cImport({
    @cDefine("GL_GLEXT_PROTOTYPES", "");
    @cInclude("GL/gl.h");
});

id: c.GLuint = undefined,
name: []const u8,
vertex_shader: ?c.GLuint = null,
fragment_shader: ?c.GLuint = null,

/// Creates an openGL program
pub fn create(name: []const u8) Zepr {
    return Zepr{ .name = name, .id = c.glCreateProgram() };
}

pub fn addVertexShader(zepr: *Zepr, source: []const u8) !void {
    zepr.vertex_shader = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(zepr.vertex_shader.?, 1, &source.ptr, null);
    c.glCompileShader(zepr.vertex_shader.?);
}

pub fn addFragmentShader(zepr: *Zepr, source: []const u8) !void {
    zepr.fragment_shader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(zepr.fragment_shader.?, 1, &source.ptr, null);
    c.glCompileShader(zepr.fragment_shader.?);
}

pub fn compile(zepr: *Zepr) !void {
    errdefer c.glDeleteProgram(zepr.id);
    if (zepr.vertex_shader == null or zepr.fragment_shader == null) unreachable;
    c.glAttachShader(zepr.id, zepr.vertex_shader.?);

    c.glAttachShader(zepr.id, zepr.vertex_shader.?);
    c.glLinkProgram(zepr.id);
    defer {
        c.glDeleteShader(zepr.vertex_shader.?);
        c.glDeleteShader(zepr.fragment_shader.?);
    }

    var success: c.GLint = undefined;
    c.glGetProgramiv(zepr.id, c.GL_LINK_STATUS, &success);
    if (success == 0) return error.ProgramLinkingFailed;
}

const Zepr = @This();
