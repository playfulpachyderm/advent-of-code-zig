const std = @import("std");

const ArrayList = std.ArrayList;

fn NDArray(comptime T: type, comptime nest_level: u8) type {
    if (nest_level == 0) {
        return ArrayList(T);
    } else {
        return ArrayList(NDArray(T, nest_level - 1));
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    var alloc = arena.allocator();

    // 3-dimensional array
    var array_3d = NDArray(u8, 3).init(alloc);

    // 2-dimensional array
    var array_2d = NDArray(u8, 2).init(alloc);
    // A 3D array contains 2D arrays, so this will work
    try array_3d.append(array_2d);

    // 1-dimensional array (i.e., just a normal ArrayList)
    var array_1d = NDArray(u8, 1).init(alloc);
    // You can add it to the 2D array
    try array_2d.append(array_1d);

    // But you CANNOT add it to the 3D array. A 3D array contains 2D arrays, not 1D arrays.
    // This will compile-error.
    try array_3d.append(array_1d);
}

//     const arraylist_type = if (_nest_level == 0) ArrayList(T) else ArrayList(NDArray(T, _nest_level - 1));
//     return struct {
//         pub usingnamespace arraylist_type;
//
//         const Self = @This();
//         const nest_level = _nest_level;
//
//         pub fn print(self: Self, alloc: std.mem.Allocator) void {
//             if (self.nest_level == 0) {
//                 std.debug.print(std.mem.join(alloc, ", "
//             }
//         };
//     };
