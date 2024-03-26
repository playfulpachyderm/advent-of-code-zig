const std = @import("std");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const File = @import("utils.zig").File;

const BlockType = enum {
    rock,
    air,
    sand,
};

const Coords = struct {
    x: u32,
    y: u32,

    fn parse(str: []const u8) Coords {
        var it = std.mem.splitScalar(u8, str, ",");
        return Coords{
            .x = std.fmt.parseInt(u32, it.next().?, 10) catch unreachable,
            .y = std.fmt.parseInt(u32, it.next().?, 10) catch unreachable,
        };
    }
};

const RockFormation = struct {
    start: Coords,
    end: Coords,

    fn parseFormations(alloc: std.mem.Allocator, str: []const u8) []RockFormation {
        var it = std.mem.splitSequence(u8, str, " -> ");
        var ret = std.ArrayList(RockFormation).init(alloc);
        var prev_coord: Coords = Coords.parse(it.next().?);
        while (it.next()) |coord| {

        }
    }
};


