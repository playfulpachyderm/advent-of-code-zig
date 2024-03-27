const std = @import("std");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const File = @import("utils.zig").File;

const Coords = struct {
    x: u32,
    y: u32,

    fn parse(str: []const u8) Coords {
        var it = std.mem.splitScalar(u8, str, ',');
        return Coords{
            .x = std.fmt.parseInt(u32, it.next().?, 10) catch unreachable,
            .y = std.fmt.parseInt(u32, it.next().?, 10) catch unreachable,
        };
    }
};

const RockFormation = struct {
    start: Coords,
    end: Coords,

    fn parseFormations(alloc: std.mem.Allocator, str: []const u8) ![]RockFormation {
        var it = std.mem.splitSequence(u8, str, " -> ");
        var ret = std.ArrayList(RockFormation).init(alloc);
        var prev_coord: Coords = Coords.parse(it.next().?);
        while (it.next()) |coord| {
            const next_coord = Coords.parse(coord);
            try ret.append(RockFormation{ .start = prev_coord, .end = next_coord });
            prev_coord = next_coord;
        }
        return ret.toOwnedSlice();
    }
};

test "parse formations" {
    var alloc = std.testing.allocator;
    const formations = try RockFormation.parseFormations(alloc, "498,4 -> 498,6 -> 496,6");
    defer alloc.free(formations);
    try expectEqual(formations.len, 2);
    try expectEqual(formations[0].start, Coords{ .x = 498, .y = 4 });
    try expectEqual(formations[0].end, Coords{ .x = 498, .y = 6 });
    try expectEqual(formations[1].start, Coords{ .x = 498, .y = 6 });
    try expectEqual(formations[1].end, Coords{ .x = 496, .y = 6 });
}

const Map = struct {
    x_min: usize,
    width: usize,
    height: usize,

    data: []BlockType, // 2D array

    const BlockType = enum {
        rock,
        air,
        sand,
    };

    inline fn get(self: Map, x: usize, y: usize) BlockType {
        return self.data[y * self.width + (x - self.x_min)];
    }
    inline fn set(self: Map, x: usize, y: usize, b: BlockType) void {
        self.data[y * self.width + (x - self.x_min)] = b;
    }
    fn parse(alloc: std.mem.Allocator, str: []const u8) !Map {
        var formations = std.ArrayList(RockFormation).init(alloc);
        defer formations.deinit();

        var buffer: [1000]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);

        var it = std.mem.splitScalar(u8, str, '\n');
        while (it.next()) |line| {
            try formations.appendSlice(try RockFormation.parseFormations(fba.allocator(), line));
            fba.reset();
        }

        // Determine map dimensions
        var x_min: u32 = std.math.maxInt(u32);
        var x_max: u32 = 0;
        var y_max: u32 = 0;
        for (formations.items) |rock| {
            if (rock.start.x < x_min) x_min = rock.start.x;
            if (rock.end.x < x_min) x_min = rock.end.x;
            if (rock.start.x > x_max) x_max = rock.start.x;
            if (rock.end.x > x_max) x_max = rock.end.x;
            if (rock.start.y > y_max) y_max = rock.start.y;
            if (rock.end.y > y_max) y_max = rock.end.y;
        }
        // Add empty space around it to simplify the flowing logic
        x_min -= 1;
        x_max += 1;
        y_max += 2;
        // Pt 2
        x_min = @min(500 - y_max, x_min);
        x_max = @max(500 + y_max, x_max);

        var ret = Map{ .x_min = x_min, .width = x_max - x_min + 1, .height = y_max, .data = undefined };
        ret.data = try alloc.alloc(BlockType, ret.width * ret.height);
        @memset(ret.data, BlockType.air);

        for (formations.items) |rock| {
            for (@min(rock.start.x, rock.end.x)..@max(rock.start.x, rock.end.x) + 1) |x| {
                for (@min(rock.start.y, rock.end.y)..@max(rock.start.y, rock.end.y) + 1) |y| {
                    ret.set(x, y, BlockType.rock);
                }
            }
        }

        return ret;
    }
    fn print(self: Map) void {
        for (0..self.height) |y| {
            for (self.x_min..self.x_min + self.width) |x| {
                const c: u8 = if (x == 500 and y == 0) '+' else switch (self.get(x, y)) {
                    .rock => '#',
                    .air => '.',
                    .sand => 'o',
                };
                std.debug.print("{c}", .{c});
            }
            std.debug.print("\n", .{});
        }
    }

    // Return true if the sand stayed in the rocks, false if it fell out
    fn drop_sand(self: *Map) bool {
        var sand = Coords{ .x = 500, .y = 0 };
        while (true) {
            if (self.get(sand.x, sand.y + 1) == .air) {
                sand.y += 1;
            } else if (self.get(sand.x - 1, sand.y + 1) == .air) {
                sand.y += 1;
                sand.x -= 1;
            } else if (self.get(sand.x + 1, sand.y + 1) == .air) {
                sand.y += 1;
                sand.x += 1;
            } else {
                // It's settled
                self.set(sand.x, sand.y, .sand);
                return true;
            }

            // Check if sand fell out
            if (sand.y >= self.height - 1) {
                return false;
            }
        }
        unreachable;
    }

    // Part 2
    fn drop_sand2(self: *Map) bool {
        var sand = Coords{ .x = 500, .y = 0 };
        while (true) {
            if (self.get(sand.x, sand.y + 1) == .air) {
                sand.y += 1;
            } else if (self.get(sand.x - 1, sand.y + 1) == .air) {
                sand.y += 1;
                sand.x -= 1;
            } else if (self.get(sand.x + 1, sand.y + 1) == .air) {
                sand.y += 1;
                sand.x += 1;
            } else {
                // It's settled
                self.set(sand.x, sand.y, .sand);
                return !(sand.x == 500 and sand.y == 0); // Pt 2: return whether the sand blocked the spawner
            }

            // Check if sand fell out
            if (sand.y >= self.height - 1) {
                //    return false;
                // Part 2: let the sand settle on the floor
                self.set(sand.x, sand.y, .sand);
                return true;
            }
        }
        unreachable;
    }
};

test "parse map" {
    const input =
        \\498,4 -> 498,6 -> 496,6
        \\503,4 -> 502,4 -> 502,9 -> 494,9
    ;
    const map = try Map.parse(std.testing.allocator, input);
    defer std.testing.allocator.free(map.data);
    //     try expectEqual(map.x_min, 493);
    //     try expectEqual(map.width, 12);
    //     try expectEqual(map.height, 11);

    try expectEqual(map.get(498, 4), Map.BlockType.rock);
    try expectEqual(map.get(498, 5), Map.BlockType.rock);
    try expectEqual(map.get(498, 6), Map.BlockType.rock);
    try expectEqual(map.get(497, 6), Map.BlockType.rock);
    try expectEqual(map.get(496, 6), Map.BlockType.rock);
    try expectEqual(map.get(495, 6), Map.BlockType.air);

    map.print();
}

test "drop sand" {
    const input =
        \\498,4 -> 498,6 -> 496,6
        \\503,4 -> 502,4 -> 502,9 -> 494,9
    ;
    var map = try Map.parse(std.testing.allocator, input);
    defer std.testing.allocator.free(map.data);

    try expect(map.drop_sand());
    try expectEqual(map.get(500, 8), Map.BlockType.sand);
    try expect(map.drop_sand());
    try expectEqual(map.get(499, 8), Map.BlockType.sand);
    try expect(map.drop_sand());
    try expectEqual(map.get(501, 8), Map.BlockType.sand);
    try expect(map.drop_sand());
    try expectEqual(map.get(500, 7), Map.BlockType.sand);
    try expect(map.drop_sand());
    try expectEqual(map.get(498, 8), Map.BlockType.sand);

    for (5..24) |_| {
        try expect(map.drop_sand());
    }
    try expect(!map.drop_sand());
    map.print();
}
test "drop sand 2" {
    const input =
        \\498,4 -> 498,6 -> 496,6
        \\503,4 -> 502,4 -> 502,9 -> 494,9
    ;
    var map = try Map.parse(std.testing.allocator, input);
    defer std.testing.allocator.free(map.data);
    var i: usize = 0;
    while (map.drop_sand2()) : (i += 1) {}
    std.debug.print("\n", .{});
    map.print();
    try expectEqual(i, 93);
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input.txt", .{});
    var buff: [50000]u8 = undefined;
    const size = try file.readAll(&buff);
    const txt = std.mem.trim(u8, buff[0..size], "\n");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var map = try Map.parse(gpa.allocator(), txt);
    defer gpa.allocator().free(map.data);

    map.print();

    var i: usize = 0;
    while (map.drop_sand2()) : (i += 1) {}
    std.debug.print("\n---------\n\n", .{});
    map.print();
    std.debug.print("Sand: {d}\n", .{i + 1});
}
