const std = @import("std");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const File = @import("utils.zig").File;

const Map = struct {
    width: usize,
    height: usize,
    data: []u32,
    S: Coords = Coords{ .x = 0, .y = 0 },
    E: Coords = Coords{ .x = 0, .y = 0 },
    alloc: std.mem.Allocator,

    S_list: std.ArrayList(Coords),
    const Coords = struct {
        x: usize,
        y: usize,
    };

    fn init(alloc: std.mem.Allocator, width: usize, height: usize) Map {
        return Map{
            .width = width,
            .height = height,
            .data = alloc.alloc(u32, height * width) catch unreachable,
            .S_list = std.ArrayList(Coords).init(alloc),
            .alloc = alloc,
        };
    }
    fn deinit(m: Map) void {
        m.S_list.deinit();
        m.alloc.free(m.data);
        std.debug.print("Freed stuff\n", .{});
    }
    fn init_dijkstra(m: *Map, S: Coords) void {
        for (0..m.width * m.height) |i| {
            m.data[i] = std.math.maxInt(u32) - 1;
        }
        m.set(S.x, S.y, 0);
    }
    fn do_dijkstra(m: *Map, t: Map) void {
        for (0..m.height) |y| {
            for (0..m.width) |x| {
                const curr = m.get(x, y);
                if (curr == 0xFFFFFFFE) continue;
                if (y != 0) {
                    if (t.get(x, y) + 1 >= t.get(x, y - 1)) {
                        m.set(x, y - 1, @min(m.get(x, y - 1), curr + 1));
                    }
                }
                if (y < m.height - 1) {
                    if (t.get(x, y) + 1 >= t.get(x, y + 1)) {
                        m.set(x, y + 1, @min(m.get(x, y + 1), curr + 1));
                    }
                }
                if (x != 0) {
                    if (t.get(x, y) + 1 >= t.get(x - 1, y)) {
                        m.set(x - 1, y, @min(m.get(x - 1, y), curr + 1));
                    }
                }
                //if (x == 1 and y == 0) {
                //    std.debug.print("x: {d}, y: {d}, map(x, y)={d}, t(x, y)={d}\n", .{ x, y, m.get(x, y), t.get(x, y) });
                //}
                if (x < m.width - 1) {
                    if (t.get(x, y) + 1 >= t.get(x + 1, y)) {
                        m.set(x + 1, y, @min(m.get(x + 1, y), curr + 1));
                    }
                }
            }
        }
    }
    fn get(m: Map, x: usize, y: usize) u32 {
        return m.data[y * m.width + x];
    }
    fn set(m: *Map, x: usize, y: usize, val: u32) void {
        m.data[y * m.width + x] = val;
    }
    fn clone(m: Map, alloc: std.mem.Allocator) Map {
        var ret = Map.init(alloc, m.width, m.height);
        for (0..m.height) |y| {
            for (0..m.width) |x| {
                ret.set(x, y, m.get(x, y));
            }
        }
        return ret;
    }
    fn parse(alloc: std.mem.Allocator, m: []const u8) Map {
        var it = std.mem.splitScalar(u8, m, '\n');
        var line = it.next().?;
        const width = line.len;
        const height = (m.len + 1) / (width + 1);
        var ret = Map.init(alloc, width, height);
        for (0..height) |y| {
            for (0..width) |x| {
                if (line[x] == 'S') {
                    ret.S = Coords{ .x = x, .y = y };
                    ret.set(x, y, 0);
                } else if (line[x] == 'E') {
                    ret.E = Coords{ .x = x, .y = y };
                    ret.set(x, y, 'z' - 'a');
                } else if (line[x] == 'a') {
                    ret.S_list.append(Coords{ .x = x, .y = y }) catch unreachable;
                    ret.set(x, y, line[x] - 'a');
                } else {
                    ret.set(x, y, line[x] - 'a');
                }
            }
            if (y != height - 1)
                line = it.next().?;
        }
        return ret;
    }

    fn print(m: Map, t: Map) void {
        for (0..m.height) |y| {
            for (0..m.width) |x| {
                if (m.get(x, y) < 0xFFFFF)
                    std.debug.print("{c}", .{@as(u8, @intCast(t.get(x, y) + 'a'))})
                else
                    std.debug.print("{c}", .{@as(u8, @intCast(t.get(x, y) + 'A'))});
            }
            std.debug.print("\n", .{});
        }
    }
};

test "map" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);

    const txt =
        \\Sabqponm
        \\abcryxxl
        \\accszExk
        \\acctuvwj
        \\abdefghi
    ;
    const map = Map.parse(arena.allocator(), txt);
    defer map.deinit();
    try expectEqual(map.width, 8);
    try expectEqual(map.height, 5);
    try expectEqual(map.S, Map.Coords{ .x = 0, .y = 0 });
    try expectEqual(map.E, Map.Coords{ .x = 5, .y = 2 });
    try expectEqual(map.get(1, 0), 0);
    var base = Map.init(arena.allocator(), map.width, map.height);
    defer base.deinit();
    base.init_dijkstra(map.S);
    base.set(map.S.x, map.S.y, 0);
    try expectEqual(base.get(0, 0), 0);
    try expectEqual(base.get(0, 1), 0xFFFFFFFE);
    std.debug.print("\n", .{});
    base.print(map);
    std.debug.print("\n", .{});

    base.do_dijkstra(map);
    try expectEqual(base.get(0, 0), 0);
    try expectEqual(base.get(1, 0), 1);
    try expectEqual(base.get(0, 1), 1);
    try expectEqual(base.get(3, 3), 0xFFFFFFFE);
    base.print(map);
    std.debug.print("\n", .{});

    base.do_dijkstra(map);
    try expectEqual(base.get(0, 0), 0);
    try expectEqual(base.get(1, 0), 1);
    try expectEqual(base.get(0, 1), 1);
    try expectEqual(base.get(1, 1), 2);
    try expectEqual(base.get(2, 0), 2);
    base.print(map);
    std.debug.print("\n", .{});

    base.do_dijkstra(map);
    defer base.deinit();
    base.print(map);
    std.debug.print("\n", .{});
    try expectEqual(base.get(0, 0), 0);
    try expectEqual(base.get(1, 0), 1);
    try expectEqual(base.get(0, 1), 1);
    try expectEqual(base.get(1, 1), 2);
    try expectEqual(base.get(3, 0), 0xFFFFFFFE);

    while (base.get(map.E.x, map.E.y) == 0xFFFFFFFE) {
        base.do_dijkstra(map);
        base.print(map);
        std.debug.print("\n", .{});
    }
    try expectEqual(base.get(map.E.x, map.E.y), 31);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());

    var file = try std.fs.cwd().openFile("input.txt", .{});
    var buff = try arena.allocator().alloc(u8, (try file.stat()).size);
    _ = try file.readAll(buff);

    const topographic = Map.parse(arena.allocator(), buff);
    var running_map = Map.init(arena.allocator(), topographic.width, topographic.height);
    running_map.init_dijkstra(topographic.S);
    while (running_map.get(topographic.E.x, topographic.E.y) == 0xFFFFFFFE) {
        running_map.do_dijkstra(topographic);
    }
    std.debug.print("Steps: {d}\n", .{running_map.get(topographic.E.x, topographic.E.y)});

    var min = running_map.get(topographic.E.x, topographic.E.y);
    starting_pts: for (topographic.S_list.items) |s| {
        running_map.init_dijkstra(s);
        var i: u32 = 0;
        while (running_map.get(topographic.E.x, topographic.E.y) == 0xFFFFFFFE) {
            i += 1;
            //std.debug.print("{d} ", .{i});
            running_map.do_dijkstra(topographic);
            if (i > min) {
                continue :starting_pts;
            }
        }
        std.debug.print("Steps: {d}\n", .{running_map.get(topographic.E.x, topographic.E.y)});
        if (running_map.get(topographic.E.x, topographic.E.y) < min)
            min = running_map.get(topographic.E.x, topographic.E.y);
    }
    std.debug.print("Steps(min): {d}\n", .{min});
}
