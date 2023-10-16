const std = @import("std");

const X = struct {
    const hi = 1;
};

const Y = struct {
    data: []const u8,
};

const Z = struct {
    bleh: u8,
    data: []const u8,
};

fn get_data(obj: anytype) []const u8 {
    if (@hasField(@TypeOf(obj), "data")) {
        return obj.data;
    } else {
        @compileError("no data field");
    }
}

pub fn main() void {
    //    const a = Y{ .data = "sdf" };
    const b = X{};

    std.debug.print("Data: {s}\n", .{get_data(b)});
}
