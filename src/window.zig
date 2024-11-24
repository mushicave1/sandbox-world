const c = @import("c.zig").c;

pub const Window = struct {
    native_window: *c.GLFWwindow,
    pixel_width: u64,
    pixel_height: u64,

    pub fn init(pixel_width: u64, pixel_height: u64, name: []const u8) !Window {
        if(c.glfwInit() == c.GL_FALSE) {
            @panic("Failed to init window");
        }

        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
        c.glfwWindowHint(c.GLFW_OPENGL_COMPAT_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
        c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
        c.glfwWindowHint(c.GLFW_RESIZABLE, c.GL_FALSE);
        c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_OPENGL_API);

        const window = c.glfwCreateWindow(@as(c_int, @intCast(pixel_width)), @as(c_int, @intCast(pixel_height)), name.ptr, null, null) orelse @panic("Failed to create GLFW window");
        c.glfwMakeContextCurrent(window);
        _ = c.glfwSetKeyCallback(window, keyCallback);
        var x_pixel_ratio: f32 = undefined;
        var y_pixel_ratio: f32 = undefined;
        c.glfwGetWindowContentScale(window, &x_pixel_ratio, &y_pixel_ratio);

        return .{
            .native_window = window, 
            .pixel_width = @as(u64, @intFromFloat(x_pixel_ratio)) * pixel_width, 
            .pixel_height = @as(u64, @intFromFloat(y_pixel_ratio)) * pixel_height
        };
    }  

    pub fn deinit(self: @This()) void {
        defer c.glfwTerminate();
        defer c.glfwDestroyWindow(self.native_window);
    }

    pub fn isRunning(self: @This()) bool {
        const state = c.glfwWindowShouldClose(self.native_window);
        switch(state) {
            0 => return true,
            1 => return false,
            else => unreachable
        }
    }

    pub fn listenToEvents(_: @This()) void {
        c.glfwPollEvents();
    }

    pub fn swapBuffers(self: @This()) void {
        c.glfwSwapBuffers(self.native_window);
    }
};


fn keyCallback(window: ?*c.GLFWwindow, key: c_int, _: c_int, action: c_int, _: c_int) callconv(.C) void {
	if(action == c.GLFW_PRESS) {
		switch(key) {
		    c.GLFW_KEY_ESCAPE => c.glfwSetWindowShouldClose(window, c.GL_TRUE),
		    else => unreachable
		}
	} 
}
