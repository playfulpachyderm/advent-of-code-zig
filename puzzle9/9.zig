const std = @import("std");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const File = @import("utils.zig").File;

const InstrType = enum {
    ADDX,
    NOOP,
};
const Instr = union(InstrType) {
    ADDX: i32,
    NOOP: void,
};

fn parse_instr(str: []const u8) !Instr {
    if (std.mem.eql(u8, str[0..4], "noop"))
        return Instr{ .NOOP = void{} };
    return Instr{ .ADDX = try std.fmt.parseInt(i32, str[5..], 10) };
}

test "parse instruction" {
    try expectEqual(Instr{ .NOOP = void{} }, try parse_instr("noop"));
    try expectEqual(Instr{ .ADDX = 325 }, try parse_instr("addx 325"));
    try expectEqual(Instr{ .ADDX = -6325 }, try parse_instr("addx -6325"));
}

fn execute_prog(alloc: std.mem.Allocator, prog: []const Instr) ![]i32 {
    var X: i32 = 1;
    var ret = std.ArrayList(i32).init(alloc);
    defer ret.deinit();
    for (prog) |instr| {
        switch (instr) {
            .NOOP => {
                try ret.append(X);
            },
            .ADDX => |val| {
                try ret.append(X);
                try ret.append(X);
                X += val;
            },
        }
    }
    return ret.toOwnedSlice();
}

test "execute program" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const prog = &[_]Instr{
        Instr{ .NOOP = void{} },
        Instr{ .ADDX = 3 },
        Instr{ .ADDX = -5 },
    };
    const result = try execute_prog(arena.allocator(), prog);
    try expectEqual(result.len, 5);
    try expectEqualSlices(i32, result, &[_]i32{ 1, 1, 1, 4, 4 });
}

fn signal_str(signals: []i32) i32 {
    var result: i32 = 0;
    for (0..6) |i| {
        result += @as(i32, @intCast(20 + 40 * i)) * signals[19 + 40 * i];
    }
    return result;
}

fn draw_result(signals: []i32) void {
    for (0..6) |y| {
        for (0..40) |x| {
            const i = y * 40 + x;
            if (signals[i] - 1 <= x and signals[i] + 1 >= x) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());

    var file = try File.new("input.txt");
    var prog = std.ArrayList(Instr).init(arena.allocator());

    while (try file.readline()) |line| {
        try prog.append(try parse_instr(line));
    }
    std.debug.print("Program: {d}\n", .{prog.items.len});
    const result = try execute_prog(arena.allocator(), prog.items);
    // for (0..6) |i| {
    //     const ii = 20 + 40 * i;
    //     std.debug.print("{d} => {d};", .{ ii, result[ii - 1] });
    // }
    std.debug.print("Strength sum: {d}\n", .{signal_str(result)});
    draw_result(result);
}
