pub const vec2 = struct {
    x: f32,
    y: f32,

    pub const Zero: vec2 =  .{ .x=0, .y=0 };
    pub const One: vec2 =   .{ .x=1, .y=1 };
    pub const UnitX: vec2 = .{ .x=1, .y=0 };
    pub const UnitY: vec2 = .{ .x=0, .y=1 };

    pub fn add(self: vec2, other: vec2) vec2 {
        var result: vec2 = undefined;
        result.x = self.x + other.x;
        result.y = self.y + other.y;
        return result;
    }

    pub fn sub(self: vec2, other: vec2) vec2 {
        var result: vec2 = undefined;
        result.x = self.x - other.x;
        result.y = self.y - other.y;
        return result;
    }

    pub fn mul(self: vec2, other: vec2) vec2 {
        var result: vec2 = undefined;
        result.x = self.x * other.x;
        result.y = self.y * other.y;
        return result;
    }

    pub fn div(self: vec2, other: vec2) vec2 {
        var result: vec2 = undefined;
        result.x = self.x / other.x;
        result.y = self.y / other.y;
        return result;
    }

    pub fn scale(self: vec2, value: f32) vec2 {
        var result: vec2 = undefined;
        result.x = self.x * value;
        result.y = self.y * value;
        return result;
    }

    pub fn neg(self: vec2) vec2 {
        var result: vec2 = undefined;
        result.x = -self.x;
        result.y = -self.y;
        return result;
    }

    pub fn dot(self: vec2, other: vec2) f32 {
        const result: f32 = self.x * other.x + self.y * other.y;
        return result;
    }

    pub fn length2(self: vec2) f32 {
        const result: f32 = self.dot(self);
        return result;
    }

    pub fn length(self: vec2) f32 {
        const result: f32 = @sqrt(self.length2());
        return result;
    }

    pub fn normalized(self: vec2) vec2 {
        const result: vec2 = self.scale(1.0 / self.length());
        return result;
    }

    pub fn normalized_safe(self: vec2) vec2 {
        const len: f32 = self.length();
        var result: vec2 = .{ 0, 0 };
        if (len != 0.0) {
            result = self.scale(1.0 / len);
        }
        return result;
    }
};

pub const vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub const Zero: vec3 =  .{ .x=0, .y=0, .z=0 };
    pub const One: vec3 =   .{ .x=1, .y=1, .z=1 };
    pub const UnitX: vec3 = .{ .x=1, .y=0, .z=0 };
    pub const UnitY: vec3 = .{ .x=0, .y=1, .z=0 };
    pub const UnitZ: vec3 = .{ .x=0, .y=0, .z=1 };

    pub fn add(self: vec3, other: vec3) vec3 {
        var result: vec3 = undefined;
        result.x = self.x + other.x;
        result.y = self.y + other.y;
        result.z = self.z + other.z;
        return result;
    }

    pub fn sub(self: vec3, other: vec3) vec3 {
        var result: vec3 = undefined;
        result.x = self.x - other.x;
        result.y = self.y - other.y;
        result.z = self.z - other.z;
        return result;
    }

    pub fn mul(self: vec3, other: vec3) vec3 {
        var result: vec3 = undefined;
        result.x = self.x * other.x;
        result.y = self.y * other.y;
        result.z = self.z * other.z;
        return result;
    }

    pub fn div(self: vec3, other: vec3) vec3 {
        var result: vec3 = undefined;
        result.x = self.x / other.x;
        result.y = self.y / other.y;
        result.z = self.z / other.z;
        return result;
    }

    pub fn scale(self: vec3, value: f32) vec3 {
        var result: vec3 = undefined;
        result.x = self.x * value;
        result.y = self.y * value;
        result.z = self.z * value;
        return result;
    }

    pub fn neg(self: vec3) vec3 {
        var result: vec3 = undefined;
        result.x = -self.x;
        result.y = -self.y;
        result.z = -self.z;
        return result;
    }

    pub fn dot(self: vec3, other: vec3) f32 {
        const result: f32 = self.x * other.x + self.y * other.y + self.z * other.z;
        return result;
    }

    pub fn length2(self: vec3) f32 {
        const result: f32 = self.dot(self);
        return result;
    }

    pub fn length(self: vec3) f32 {
        const result: f32 = @sqrt(self.length2());
        return result;
    }

    pub fn normalized(self: vec3) vec3 {
        const result: vec3 = self.scale(1.0 / self.length());
        return result;
    }

    pub fn normalized_safe(self: vec3) vec3 {
        const len: f32 = self.length();
        var result: vec3 = .{ 0, 0 };
        if (len != 0.0) {
            result = self.scale(1.0 / len);
        }
        return result;
    }

    pub fn cross(self: vec3, other: vec3) vec3 {
        var result: vec3 = undefined;
        result.x = self.y * other.z - other.y * self.z;
	    result.y = self.z * other.x - other.z * self.x;
	    result.z = self.x * other.y - other.x * self.y;
        return result;
    }
};

pub const vec4 = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub const Zero: vec4 =  .{ .x=0, .y=0, .z=0, .w=0 };
    pub const One: vec4 =   .{ .x=1, .y=1, .z=1, .w=1 };
    pub const UnitX: vec4 = .{ .x=1, .y=0, .z=0, .w=0 };
    pub const UnitY: vec4 = .{ .x=0, .y=1, .z=0, .w=0 };
    pub const UnitZ: vec4 = .{ .x=0, .y=0, .z=1, .w=0 };
    pub const UnitW: vec4 = .{ .x=0, .y=0, .z=0, .w=1 };

    pub fn add(self: vec4, other: vec4) vec4 {
        var result: vec4 = undefined;
        result.x = self.x + other.x;
        result.y = self.y + other.y;
        result.z = self.z + other.z;
        result.w = self.w + other.w;
        return result;
    }

    pub fn sub(self: vec4, other: vec4) vec4 {
        var result: vec4 = undefined;
        result.x = self.x - other.x;
        result.y = self.y - other.y;
        result.z = self.z - other.z;
        result.w = self.w - other.w;
        return result;
    }

    pub fn mul(self: vec4, other: vec4) vec4 {
        var result: vec4 = undefined;
        result.x = self.x * other.x;
        result.y = self.y * other.y;
        result.z = self.z * other.z;
        result.w = self.w * other.w;
        return result;
    }

    pub fn div(self: vec4, other: vec4) vec4 {
        var result: vec4 = undefined;
        result.x = self.x / other.x;
        result.y = self.y / other.y;
        result.z = self.z / other.z;
        result.w = self.w / other.w;
        return result;
    }

    pub fn scale(self: vec4, value: f32) vec4 {
        var result: vec4 = undefined;
        result.x = self.x * value;
        result.y = self.y * value;
        result.z = self.z * value;
        result.w = self.w * value;
        return result;
    }

    pub fn neg(self: vec4) vec4 {
        var result: vec4 = undefined;
        result.x = -self.x;
        result.y = -self.y;
        result.z = -self.z;
        result.w = -self.w;
        return result;
    }

    pub fn dot(self: vec4, other: vec4) f32 {
        const result: f32 = self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w;
        return result;
    }

    pub fn length2(self: vec4) f32 {
        const result: f32 = self.dot(self);
        return result;
    }

    pub fn length(self: vec4) f32 {
        const result: f32 = @sqrt(self.length2());
        return result;
    }

    pub fn normalized(self: vec4) vec4 {
        const result: vec4 = self.scale(1.0 / self.length());
        return result;
    }

    pub fn normalized_safe(self: vec4) vec4 {
        const len: f32 = self.length();
        var result: vec4 = .{ 0, 0 };
        if (len != 0.0) {
            result = self.scale(1.0 / len);
        }
        return result;
    }
};

pub const mat4 = struct {
    elements: [4][4]f32,

    pub const Zero: mat4 = .{
        .elements = [4][4]f32{
            .{0, 0, 0, 0},
            .{0, 0, 0, 0},
            .{0, 0, 0, 0},
            .{0, 0, 0, 0}
        }
    };

    pub const Identity: mat4 = .{
        .elements = [4][4]f32{
            .{1, 0, 0, 0},
            .{0, 1, 0, 0},
            .{0, 0, 1, 0},
            .{0, 0, 0, 1}
        }
    };

    pub fn mul(self: mat4, other: mat4) mat4 {
        var result: mat4 = undefined;

        for (0..4) |i| {
            const row = @Vector(4, f32){self.elements[0][i], self.elements[1][i], self.elements[2][i], self.elements[3][i]};
            for (0..4) |j| {
                const col = @Vector(4, f32){other.elements[j][0], other.elements[j][1], other.elements[j][2], other.elements[j][3]};
                result.elements[j][i] = @reduce(.Add, row * col);
            }
        }

        return result;
    }

    pub fn mul_vec(self: mat4, v: vec4) vec4 {
        var result: vec4 = undefined;
        const vec = @Vector(4, f32){v.x, v.y, v.z, v.w};

        for (0..4) |i| {
            const row = @Vector(4, f32){self.elements[0][i], self.elements[1][i], self.elements[2][i], self.elements[3][i]};
            switch (i) {
                0 => {result.x = @reduce(.Add, row * vec);},
                1 => {result.y = @reduce(.Add, row * vec);},
                2 => {result.z = @reduce(.Add, row * vec);},
                3 => {result.w = @reduce(.Add, row * vec);},
                else => {}
            }
        }

        return result;
    }
};

pub fn ortho(left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) mat4 {
    var result: mat4 = mat4.Identity;

    result.elements[0][0] = 2.0 / (right - left);
	result.elements[1][1] = 2.0 / (top - bottom);
	result.elements[2][2] = -2.0 / (far - near);

    result.elements[3][0] = -(right + left) / (right - left);
	result.elements[3][1] = -(top + bottom) / (top - bottom);
    result.elements[3][2] = -(far + near) / (far - near);

    return result;
}

pub fn perspective(fovy: f32, aspect_ratio: f32, near: f32, far: f32) mat4 {
    var result: mat4 = mat4.Zero;
    const tan_hfov = @tan(fovy * 0.5);
    
    result.elements[0][0] = 1.0 / (aspect_ratio * tan_hfov);
    result.elements[1][1] = 1.0 / tan_hfov;
    result.elements[2][2] = -(far + near) / (far - near);
    result.elements[2][3] = -1.0;
    result.elements[3][2] = -2 * far * near / (far - near);

    return result;
}

pub fn look_at(eye: vec3, target: vec3, world_up: vec3) mat4 {
    var result: mat4 = mat4.Identity;

    const forward = target.sub(eye).normalized();
    const right = forward.cross(world_up).normalized();
    const up = right.cross(forward);

    result.elements[0][0] = right.x; result.elements[1][0] = up.x; result.elements[2][0] = -forward.x; result.elements[3][0] = -right.dot(eye);
    result.elements[0][1] = right.y; result.elements[1][1] = up.y; result.elements[2][1] = -forward.y; result.elements[3][1] = -up.dot(eye);
    result.elements[0][2] = right.z; result.elements[1][2] = up.z; result.elements[2][2] = -forward.z; result.elements[3][2] = forward.dot(eye);

    return result;
}

pub fn translate(translation: vec3) mat4 {
    var result: mat4 = mat4.Identity;

    result.elements[3][0] = translation.x;
    result.elements[3][1] = translation.y;
    result.elements[3][2] = translation.z;

    return result;
}

pub fn scale(factor: vec3) mat4 {
    var result: mat4 = mat4.Identity;

    result.elements[0][0] = factor.x;
    result.elements[1][1] = factor.y;
    result.elements[2][2] = factor.z;

    return result;
}

pub fn rotate_axis(axis: vec3, angle: f32) mat4 {
    var result: mat4 = mat4.Identity;

    const c = @cos(angle);
    const s = @sin(angle);
    const a = axis.normalized();
    const t = a.scale(1.0 - c);

    result.elements[0][0] = c + t.x * a.x;
    result.elements[0][1] = t.x * a.y + s * a.z;
    result.elements[0][2] = t.x * a.z - s * a.y;
    result.elements[0][3] = 0;

    result.elements[1][0] = t.y * a.x - s * a.z;
    result.elements[1][1] = c + t.y * a.y;
    result.elements[1][2] = t.x * a.z + s * a.x;
    result.elements[1][3] = 0;

    result.elements[2][0] = t.z * a.x + s * a.y;
    result.elements[2][1] = t.z * a.y - s * a.x;
    result.elements[2][2] = c + t.z * a.z;
    result.elements[2][3] = 0;

    return result;
}