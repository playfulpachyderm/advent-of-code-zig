const std = @import("std");

const expectEqual = std.testing.expectEqual;
const File = @import("utils.zig").File;

fn Window(comptime size: usize) type {
    return struct {
        const Self = @This();

        data: [size]u8,

        pub fn new() Self {
            var ret = Self{ .data = [_]u8{0} ** size };
            return ret;
        }
        pub fn check(self: Self) bool {
            var vals: [128]bool = .{false} ** 128;
            for (0..size) |val| {
                vals[self.data[val]] = true;
            }
            var total: u8 = 0;
            for (0..128) |i| {
                if (vals[i]) total += 1;
            }
            return total == size;
        }
    };
}

const window_size = 14;

fn solve(stream: []const u8) usize {
    var i: usize = window_size;
    var window = Window(window_size).new();

    for (0..window_size) |j| {
        window.data[j] = stream[j];
    }

    while (!window.check()) {
        window.data[@mod(i, window_size)] = stream[i];
        i += 1;
    }
    return i;
}
test "solve" {
    // try expectEqual(solve("mjqjpqmgbljsphdztnvjfqwrcgsmlb"), 7);
    // try expectEqual(solve("bvwbjplbgvbhsrlpgdmjqwftvncz"), 5);
    // try expectEqual(solve("nppdvjthqldpwncqszvftbrmjlhg"), 6);
    // try expectEqual(solve("nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg"), 10);
    // try expectEqual(solve("zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw"), 11);
    try expectEqual(solve("mjqjpqmgbljsphdztnvjfqwrcgsmlb"), 19);
    try expectEqual(solve("bvwbjplbgvbhsrlpgdmjqwftvncz"), 23);
    try expectEqual(solve("nppdvjthqldpwncqszvftbrmjlhg"), 23);
    try expectEqual(solve("nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg"), 29);
    try expectEqual(solve("zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw"), 26);
}

pub fn main() !void {
    var file = try File.new("input.txt");
    const result = solve((try file.readline()).?);
    std.debug.print("Answer: {d}\n", .{result});
}
