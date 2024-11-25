const std = @import("std");
const gl = @import("gfx/gl.zig");
const math = @import("math/math.zig");
const c = @import("c.zig").c;
const w = @import("window.zig");
const file = @import("file.zig");

const writer = std.io.getStdOut().writer();

pub fn main() !void {
	var window = try w.Window.init(600, 400, "Window");

	defer window.deinit();

	// Renderer
	// ---------------------------
	c.glViewport(0, 0, @as(c_int, @intCast(window.pixel_width)), @as(c_int, @intCast(window.pixel_height)));

	// Shader Program
	// ----------------------------
	const vertex_shader_source = try file.readFile("assets/shaders/basic.vert");
	defer std.heap.page_allocator.free(vertex_shader_source);

	const fragment_shader_source = try file.readFile("assets/shaders/basic.frag");
	defer std.heap.page_allocator.free(fragment_shader_source);

	const program = try gl.GLProgram.init(vertex_shader_source, fragment_shader_source);
	defer program.deinit();
	// ----------------------------


	// Geometry
	// ----------------------------
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
	// ----------------------------



	// Mesh
	// ---------------------------
	var position = [2]f32{0.0, 0.0};
	var size = [2]f32{1.0, 1.0};

	var model = math.mat4x4(
		&math.vec4(1.0, 0.0, 0.0, 0.0),
		&math.vec4(0.0, 1.0, 0.0, 0.0),
		&math.vec4(0.0, 0.0, 1.0, 0.0),
		&math.vec4(0.0, 0.0, 0.0, 1.0),
	);
	// ---------------------------


	while(window.isRunning() == true) {
		window.listenToEvents();
		
		c.glClear(c.GL_COLOR_BUFFER_BIT);
		c.glClearColor(0.5, 0.0, 0.5, 1.0);

		if(c.glfwGetKey(window.native_window, c.GLFW_KEY_W) == c.GLFW_PRESS) 
		{
		position[1] += 0.01;
		}
		if(c.glfwGetKey(window.native_window, c.GLFW_KEY_A) == c.GLFW_PRESS) 
		{
		position[0] -= 0.01;
		}
		if(c.glfwGetKey(window.native_window, c.GLFW_KEY_S) == c.GLFW_PRESS) 
		{
		position[1] -= 0.01;
		}
		if(c.glfwGetKey(window.native_window, c.GLFW_KEY_D) == c.GLFW_PRESS) 
		{
		position[0] += 0.01;
		}

		if(c.glfwGetKey(window.native_window, c.GLFW_KEY_UP) == c.GLFW_PRESS) 
		{
		size[1] += 0.01;
		}
		if(c.glfwGetKey(window.native_window, c.GLFW_KEY_LEFT) == c.GLFW_PRESS) 
		{
		size[0] -= 0.01;
		}
		if(c.glfwGetKey(window.native_window, c.GLFW_KEY_DOWN) == c.GLFW_PRESS) 
		{
		size[1] -= 0.01;
		}
		if(c.glfwGetKey(window.native_window, c.GLFW_KEY_RIGHT) == c.GLFW_PRESS) 
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

		window.swapBuffers();
	}
}
