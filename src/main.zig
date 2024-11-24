const std = @import("std");
const gl = @import("gfx/gl.zig");
const math = @import("math/math.zig");

const writer = std.io.getStdOut().writer();

const c = @cImport({
	@cInclude("epoxy/gl.h");
	@cInclude("GLFW/glfw3.h");
	@cInclude("stdio.h");
});

pub fn main() !void {
	if(c.glfwInit() == c.GL_FALSE) {
		@panic("Failed to init window");
	}
	defer c.glfwTerminate();

	c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
	c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
	c.glfwWindowHint(c.GLFW_OPENGL_COMPAT_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
	c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
	c.glfwWindowHint(c.GLFW_RESIZABLE, c.GL_FALSE);
	c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_OPENGL_API);

	const window = c.glfwCreateWindow(600, 400, "sandbox-world", null, null) orelse @panic("Failed to create GLFW window");
	defer c.glfwDestroyWindow(window);

	c.glfwMakeContextCurrent(window);

	_ = c.glfwSetKeyCallback(window, keyCallback);

	var x_pixel_ratio: f32 = undefined;
	var y_pixel_ratio: f32 = undefined;
	c.glfwGetWindowContentScale(window, &x_pixel_ratio, &y_pixel_ratio);


	c.glViewport(0, 0, 600 * @as(c_int, @intFromFloat(x_pixel_ratio)), 400 * @as(c_int, @intFromFloat(y_pixel_ratio)));

	const vertex_shader_source = 
		\\ #version 330 core
		\\ layout (location = 0) in vec3 aPos;
		\\
		\\out vec3 v_vertex_position;
		\\
		\\uniform mat4 u_model;
		\\
		\\ void main() {
		\\     v_vertex_position = aPos;
		\\     gl_Position = u_model * vec4(aPos, 1.0);
		\\}
	;

	const fragment_shader_source = 
		\\ #version 330 core
		\\ layout (location = 0) out vec4 frag_pos;
		\\
		\\ in vec3 v_vertex_position;
		\\
		\\ void main() {
		\\     frag_pos = vec4(v_vertex_position, 1.0);
		\\}
		;

	const program = try gl.GLProgram.init(vertex_shader_source, fragment_shader_source);
	defer program.deinit();

	const vertices: [12]f32 = .{
		-0.5, -0.5, 1.0,
		-0.5, 0.5, 1.0,
		0.5, 0.5, 1.0,
		0.5, -0.5, 1.0
	};

	const vertex_buffer = gl.GLBuffer.init(gl.BufferUsage.vertex_buffer, &vertices, vertices.len * @sizeOf(f32));
	defer vertex_buffer.deinit();

	const indices = [_]u8{
		0, 1, 2,
		2, 3, 0
	};
	
	const index_buffer = gl.GLBuffer.init(gl.BufferUsage.index_buffer, &indices, indices.len * @sizeOf(u8));
	defer index_buffer.deinit();

	var attributes = [_]gl.BufferAttribute{
		gl.BufferAttribute.init(3, gl.ValueType.float),
	};
	const vertex_layout = gl.BufferLayout.init(&attributes, 1);
	const vertex_input = gl.VertexInput.init(vertex_buffer, vertex_layout, index_buffer);
	defer vertex_input.deinit();

	var position = [2]f32{0.0, 0.0};
	var size = [2]f32{1.0, 1.0};

	var model = math.mat4x4(
		&math.vec4(1.0, 0.0, 0.0, 0.0),
		&math.vec4(0.0, 1.0, 0.0, 0.0),
		&math.vec4(0.0, 0.0, 1.0, 0.0),
		&math.vec4(0.0, 0.0, 0.0, 1.0),
	);

	while(c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
		c.glfwPollEvents();
		c.glClear(c.GL_COLOR_BUFFER_BIT);
		c.glClearColor(0.5, 0.0, 0.5, 1.0);

		if(c.glfwGetKey(window, c.GLFW_KEY_W) == c.GLFW_PRESS) 
		{
		position[1] += 0.01;
		}
		if(c.glfwGetKey(window, c.GLFW_KEY_A) == c.GLFW_PRESS) 
		{
		position[0] -= 0.01;
		}
		if(c.glfwGetKey(window, c.GLFW_KEY_S) == c.GLFW_PRESS) 
		{
		position[1] -= 0.01;
		}
		if(c.glfwGetKey(window, c.GLFW_KEY_D) == c.GLFW_PRESS) 
		{
		position[0] += 0.01;
		}

		if(c.glfwGetKey(window, c.GLFW_KEY_UP) == c.GLFW_PRESS) 
		{
		size[1] += 0.01;
		}
		if(c.glfwGetKey(window, c.GLFW_KEY_LEFT) == c.GLFW_PRESS) 
		{
		size[0] -= 0.01;
		}
		if(c.glfwGetKey(window, c.GLFW_KEY_DOWN) == c.GLFW_PRESS) 
		{
		size[1] -= 0.01;
		}
		if(c.glfwGetKey(window, c.GLFW_KEY_RIGHT) == c.GLFW_PRESS) 
		{
		size[0] += 0.01;
		}

		const translate = math.Mat4x4.translate(math.vec3(position[0], position[1], 0.0));
		const scale = math.Mat4x4.scale(math.vec3(size[0], size[1], 0.0));
		model = math.Mat4x4.mul(&translate, &scale);
		
		program.bind();
		program.setUniform(f32, "u_model", &model.v[0].v[0]);
		vertex_input.bind();

		c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_BYTE, null);

		c.glfwSwapBuffers(window);
	}
}


fn keyCallback(window: ?*c.GLFWwindow, key: c_int, _: c_int, action: c_int, _: c_int) callconv(.C) void {
	if(action == c.GLFW_PRESS) {
		switch(key) {
		c.GLFW_KEY_ESCAPE => c.glfwSetWindowShouldClose(window, c.GL_TRUE),
		else => {}
		}
	} 
}
