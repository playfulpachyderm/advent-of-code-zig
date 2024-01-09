const std = @import("std");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

const File = @import("utils.zig").File;

const Map = struct {
    data: [][]const u8,

    fn parse(alloc: std.mem.Allocator, input: []const u8) Map {
        var list_data = std.ArrayList([]const u8).init(alloc);
        defer list_data.deinit();
        var it = std.mem.splitScalar(u8, std.mem.trim(u8, input, "\n"), '\n');
        while (it.next()) |line| {
            //     for (line) |*i| {
            //         i.* -= '0';
            //     }
            std.debug.print("line: {s} (length: {d})\n", .{ line, line.len });
            list_data.append(alloc.dupe(u8, line) catch unreachable) catch unreachable;
        }
        return Map{ .data = list_data.toOwnedSlice() catch unreachable };
    }

    fn is_visible(self: Map, y: usize, x: usize) bool {
        // Edges
        if (x == 0 or y == 0 or y == self.data.len or x == self.data[0].len) {
            std.debug.print("visible from perimeter\n", .{});
            return true;
        }

        var blocked = for (0..y) |i| {
            if (self.data[i][x] >= self.data[y][x]) {
                break true;
            }
        } else false;
        if (!blocked) {
            std.debug.print("visible from top\n", .{});
            return true;
        }

        blocked = for (y + 1..self.data.len) |i| {
            if (self.data[i][x] >= self.data[y][x]) {
                break true;
            }
        } else false;
        if (!blocked) {
            std.debug.print("visible from bottom\n", .{});
            return true;
        }

        blocked = for (0..x) |i| {
            if (self.data[y][i] >= self.data[y][x]) {
                break true;
            }
        } else false;
        if (!blocked) {
            std.debug.print("visible from left\n", .{});
            return true;
        }

        blocked = for (x + 1..self.data[0].len) |i| {
            if (self.data[y][i] >= self.data[y][x]) {
                break true;
            }
        } else false;
        if (!blocked) {
            std.debug.print("visible from right\n", .{});
            return true;
        }

        return false;
    }

    fn viewing_distance(self: Map, y: usize, x: usize) usize {
        // Edges
        if (x == 0 or y == 0 or y == self.data.len or x == self.data[0].len) {
            std.debug.print("visible from perimeter\n", .{});
            return 0;
        }
        const directions = [4]usize{
            blk: {
                var trees: usize = 1;
                var y_i: usize = y - 1;
                while (y_i > 0) : ({
                    y_i -= 1;
                    trees += 1;
                }) {
                    std.debug.print("Tree height: {c}\n", .{self.data[y_i][x]});
                    if (self.data[y_i][x] >= self.data[y][x])
                        break;
                }
                std.debug.print("up: {d}\n", .{trees});
                break :blk trees;
            },
            blk: {
                var trees: usize = 1;
                var x_i: usize = x - 1;
                while (x_i > 0) : ({
                    x_i -= 1;
                    trees += 1;
                }) {
                    std.debug.print("Tree height: {c}\n", .{self.data[y][x_i]});
                    if (self.data[y][x_i] >= self.data[y][x])
                        break;
                }
                std.debug.print("left: {d}\n", .{trees});
                break :blk trees;
            },
            blk: {
                var trees: usize = 0;
                for (y + 1..self.data.len) |y_i| {
                    trees += 1;
                    if (self.data[y_i][x] >= self.data[y][x])
                        break;
                }
                std.debug.print("down: {d}\n", .{trees});
                break :blk trees;
            },
            blk: {
                var trees: usize = 0;
                for (x + 1..self.data[y].len) |x_i| {
                    trees += 1;
                    if (self.data[y][x_i] >= self.data[y][x])
                        break;
                }
                std.debug.print("right: {d}\n", .{trees});
                break :blk trees;
            },
        };
        return directions[0] * directions[1] * directions[2] * directions[3];
    }
};

test "parse map" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const data =
        \\30373
        \\25512
        \\65332
        \\33549
        \\35390
    ;
    const map = Map.parse(arena.allocator(), data);
    std.debug.print("Map line 1: {s}\n", .{map.data[0]});
    try expectEqual(map.data.len, 5);
    try expectEqual(map.data[0].len, 5);
    try expectEqual(map.data[0][0], '3');
    try expect(map.is_visible(0, 0));
    try expect(!map.is_visible(1, 3));

    const visibilities = [_][]const bool{
        &.{ true, true, true, true, true },
        &.{ true, true, true, false, true },
        &.{ true, true, false, true, true },
        &.{ true, false, true, false, true },
        &.{ true, true, true, true, true },
    };
    for (0..visibilities.len) |y| {
        for (0..visibilities[y].len) |x| {
            std.debug.print("x: {d}, y: {d}\n", .{ x, y });
            try expectEqual(visibilities[y][x], map.is_visible(y, x));
        }
    }
}

test "viewing distance" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const data =
        \\30373
        \\25512
        \\65332
        \\33549
        \\35390
    ;
    const map = Map.parse(arena.allocator(), data);

    try expectEqual(map.viewing_distance(1, 2), 4);
    try expectEqual(map.viewing_distance(3, 2), 8);
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    var buff = try arena.allocator().alloc(u8, (try file.stat()).size);
    _ = try file.readAll(buff);
    std.debug.print("File:\n{s}\n", .{buff});

    const map = Map.parse(arena.allocator(), buff);
    std.debug.print("Width: {d}, height: {d}\n", .{ map.data[0].len, map.data.len });
    var total: usize = 0;
    var max_view: usize = 0;
    var max_x: usize = 0;
    var max_y: usize = 0;
    for (0..map.data.len) |y| {
        for (0..map.data[y].len) |x| {
            if (map.is_visible(y, x)) {
                total += 1;
            }
            const view = map.viewing_distance(y, x);
            if (view > max_view) {
                max_view = view;
                max_x = x;
                max_y = y;
            }
        }
    }
    std.debug.print("Visible: {d}\n", .{total});
    std.debug.print("Max view: {d}, at x={d},y={d}\n", .{ max_view, max_x, max_y });
}
