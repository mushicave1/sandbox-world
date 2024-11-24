const std = @import("std");
const writer = std.io.getStdOut().writer();
const c = @import("../c.zig").c;



pub const BufferUsage = enum {
    vertex_buffer,
    index_buffer,

    pub fn gl(self: @This()) c.GLuint {
        return switch(self) {
            BufferUsage.vertex_buffer => c.GL_ARRAY_BUFFER,
            BufferUsage.index_buffer => c.GL_ELEMENT_ARRAY_BUFFER,
        };
    }
};

pub const ValueType = enum {
    unsigned_byte,
    signed_byte,
    int_8,
    unsigned_int_8,
    int_16,
    unsigned_int_16,
    int_32,
    unsigned_int_32,
    float,
    double,

    pub fn gl(self: @This()) c.GLuint {
        return switch(self) {
            ValueType.unsigned_byte => c.GL_UNSIGNED_BYTE,
            ValueType.signed_byte => c.GL_BYTE,
            ValueType.int_8 => c.GL_INT,
            ValueType.unsigned_int_8 => c.GL_UNSIGNED_INT,
            ValueType.int_16 => c.GL_INT,
            ValueType.unsigned_int_16 => c.GL_UNSIGNED_INT,
            ValueType.int_32 => c.GL_INT,
            ValueType.unsigned_int_32 => c.GL_UNSIGNED_INT,
            ValueType.float => c.GL_FLOAT,
            ValueType.double => c.GL_DOUBLE,
        };
    }

    pub fn byteSize(self: @This()) u64 {
        return switch(self) {
            ValueType.unsigned_byte => 1,
            ValueType.signed_byte => 1,
            ValueType.int_8 => 1,
            ValueType.unsigned_int_8 => 1,
            ValueType.int_16 => 2,
            ValueType.unsigned_int_16 => 2,
            ValueType.int_32 => 4,
            ValueType.unsigned_int_32 => 4,
            ValueType.float => 4,
            ValueType.double => 8,
        };
    }
};

pub const GLProgram = struct {
    handle: c.GLuint = 0,

    pub fn init(v_shader_src: []const u8, f_shader_src: []const u8) !@This()
    {
        const vertex_shader: c.GLuint = c.glCreateShader(c.GL_VERTEX_SHADER);
        defer c.glDeleteShader(vertex_shader);
        c.glShaderSource(vertex_shader, 1, &v_shader_src.ptr, &@intCast(v_shader_src.len));
        c.glCompileShader(vertex_shader);
        var success: c.GLint = undefined;
        c.glGetShaderiv(vertex_shader, c.GL_LINK_STATUS, &success);
        if(success == c.GL_FALSE) 
        {
            var infolog: [512]u8 = undefined;
            c.glGetProgramInfoLog(vertex_shader, 512, null, &infolog[0]);
            try writer.print("SHADER_COMPILE_ERROR: \n{s}\n", .{infolog});
        }

        const fragment_shader: c.GLuint = c.glCreateShader(c.GL_FRAGMENT_SHADER);
        defer c.glDeleteShader(fragment_shader);
        c.glShaderSource(fragment_shader, 1, &f_shader_src.ptr, &@intCast(f_shader_src.len));
        c.glCompileShader(fragment_shader);
        c.glGetShaderiv(fragment_shader, c.GL_LINK_STATUS, &success);
        if(success == c.GL_FALSE) 
        {
            var infolog: [512]u8 = undefined;
            c.glGetProgramInfoLog(fragment_shader, 512, null, &infolog[0]);
            try writer.print("SHADER_COMPILE_ERROR: \n{s}\n", .{infolog});
        }

        const handle = c.glCreateProgram();
        c.glAttachShader(handle, vertex_shader);
        c.glAttachShader(handle, fragment_shader);
        c.glLinkProgram(handle);
        c.glGetProgramiv(handle, c.GL_LINK_STATUS, &success);
        if (success == c.GL_FALSE) 
        {
            var infolog: [512]u8 = undefined;
            c.glGetProgramInfoLog(handle, 512, null, &infolog);
            try writer.print("ERROR::PROGRAM::LINKING_FAILED: \n{s}\n", .{infolog});
        }

        return .{.handle = handle};
    }

    pub fn setUniform(self: @This(), comptime T: type, name: []const u8, args: *T) void {
        switch(T) {
            f32 => c.glUniformMatrix4fv(c.glGetUniformLocation(self.handle, name.ptr), 1, c.GLFW_FALSE, args),
            else => {}
        }
    }

    pub fn bind(self: @This()) void {
        c.glUseProgram(self.handle);
    }

    pub fn deinit(self: @This()) void
    {
        c.glDeleteProgram(self.handle);
    }
};

pub const GLBuffer = struct {
    handle: c.GLuint = 0,
    usage: c.GLuint = 0,

    pub fn init(usage: BufferUsage, args: *const anyopaque, byte_size: u32) @This() {
        var handle: c.GLuint = undefined;
        c.glGenBuffers(1, &handle);
        c.glBindBuffer(usage.gl(), handle);
        c.glBufferData(usage.gl(), byte_size, args, c.GL_STATIC_DRAW);

        return .{.handle = handle, .usage = usage.gl()};
    }

    pub fn bind(self: @This()) void {
        c.glBindBuffer(self.usage, self.handle);
    }

    pub fn deinit(self: @This()) void {
        c.glDeleteBuffers(1, &self.handle);
    }
};


pub const BufferAttribute = struct {
    count: u64 = 0,
    value_type: ValueType,
    byte_offset: u64 = 0,

    pub fn init(len: u64, value_type: ValueType) @This() {
        return .{
            .count = len,
            .value_type = value_type,
            // Unable to calculate offset here w/o knowing the other attributes belonging to the VertexLayout.
        };
    }
};

pub const BufferLayout = struct {
    byte_stride: u64 = 0,
    attributes: []BufferAttribute,

    pub fn init(attributes: []BufferAttribute, len: u64) @This() {
        var stride: u64 = 0;
        for(0..len) |i| {
            attributes[i].byte_offset = stride;
            stride += (attributes[i].value_type.byteSize() * attributes[i].count);
        }

        return .{.byte_stride = stride, .attributes = attributes};
    }
};


pub const VertexInput = struct {
    handle: c.GLuint = 0,

    pub fn init(vertex_buffer: GLBuffer, layout: BufferLayout, index_buffer: ?GLBuffer) @This() {
        var handle: c.GLuint = undefined;
        c.glGenVertexArrays(1, &handle);
        c.glBindVertexArray(handle);
        c.glBindBuffer(vertex_buffer.usage, vertex_buffer.handle);
        c.glBindBuffer(index_buffer.?.usage, index_buffer.?.handle);

        for(0..layout.attributes.len) |i| {
            const attrib = layout.attributes[i];
            c.glVertexAttribPointer(@as(c_uint, @intCast(i)), @as(c_int, @intCast(attrib.count)), attrib.value_type.gl(), c.GL_FALSE, @as(c_int, @intCast(layout.byte_stride)), @ptrFromInt(attrib.byte_offset));
            c.glEnableVertexAttribArray(@as(c_uint, @intCast(i)));
        }

        c.glBindVertexArray(c.GL_NONE);

        return .{.handle = handle};
    }

    pub fn bind(self: @This()) void {
        c.glBindVertexArray(self.handle);
    }

    pub fn deinit(self: @This()) void {
        c.glDeleteVertexArrays(1, &self.handle);
    }
};