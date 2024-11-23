const std = @import("std");
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

  const vertex_shader: c.GLuint = c.glCreateShader(c.GL_VERTEX_SHADER);
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
  c.glShaderSource(vertex_shader, 1, &vertex_shader_source.ptr, &@intCast(vertex_shader_source.len));
  c.glCompileShader(vertex_shader);
  var success: c.GLint = undefined;
  c.glGetShaderiv(vertex_shader, c.GL_LINK_STATUS, &success);
  if (success == c.GL_FALSE) {
      var infolog: [512]u8 = undefined;
      c.glGetProgramInfoLog(vertex_shader, 512, null, &infolog[0]);
      try writer.print("SHADER_COMPILE_ERROR: \n{s}\n", .{infolog});
  }

  const fragment_shader: c.GLuint = c.glCreateShader(c.GL_FRAGMENT_SHADER);
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
  c.glShaderSource(fragment_shader, 1, &fragment_shader_source.ptr, &@intCast(fragment_shader_source.len));
  c.glCompileShader(fragment_shader);
  c.glGetShaderiv(fragment_shader, c.GL_LINK_STATUS, &success);
  if (success == c.GL_FALSE) {
      var infolog: [512]u8 = undefined;
      c.glGetProgramInfoLog(fragment_shader, 512, null, &infolog[0]);
      try writer.print("SHADER_COMPILE_ERROR: \n{s}\n", .{infolog});
  }

  const program: c.GLuint = c.glCreateProgram();
  c.glAttachShader(program, vertex_shader);
  c.glAttachShader(program, fragment_shader);
  c.glLinkProgram(program);
  c.glGetProgramiv(program, c.GL_LINK_STATUS, &success);
  if (success == c.GL_FALSE) {
      var infolog: [512]u8 = undefined;
      c.glGetProgramInfoLog(program, 512, null, &infolog);
      try writer.print("ERROR::PROGRAM::LINKING_FAILED: \n{s}\n", .{infolog});
  }

  defer c.glDeleteShader(fragment_shader);
  defer c.glDeleteShader(vertex_shader);


  var vbo: c.GLuint = undefined;
  c.glGenBuffers(1, &vbo);
  c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
  defer c.glDeleteBuffers(1, &vbo);
  const vertices: [12]f32 = .{
    -0.5, -0.5, 1.0,
    -0.5, 0.5, 1.0,
    0.5, 0.5, 1.0,
    0.5, -0.5, 1.0
  };
  c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, c.GL_STATIC_DRAW);

  var ebo: c.GLuint = undefined;
  c.glGenBuffers(1, &ebo);
  defer c.glDeleteBuffers(1, &ebo);
  c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
  const indices = [_]u8{
    0, 1, 2,
    2, 3, 0
  };
  c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(u8), &indices, c.GL_STATIC_DRAW);

  var vao: c.GLuint = undefined;
  c.glGenVertexArrays(1, &vao);
  defer c.glDeleteVertexArrays(1, &vao);
  c.glBindVertexArray(vao);
  c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
  c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
  c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
  c.glEnableVertexAttribArray(0);
  c.glBindVertexArray(0);



  var position = [2]f32{0.0, 0.0};
  var size = [2]f32{1.0, 1.0};

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

    var model_matrix = [4][4]f32{
      [4]f32{size[0], 0.0, 0.0, position[0]},
      [4]f32{0.0, size[1], 0.0, position[1]},
      [4]f32{0.0, 0.0, 1.0, 0.0},
      [4]f32{0.0, 0.0, 0.0, 1.0}
    };

    c.glUseProgram(program);

    c.glUniformMatrix4fv(c.glGetUniformLocation(program, "u_model"), 1, c.GLFW_TRUE, &model_matrix[0][0]);

    c.glBindVertexArray(vao);
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
