const std = @import("std");

const expectEqual = std.testing.expectEqual;

const File = @import("utils.zig").File;

const Elf = struct {
    min: u32,
    max: u32,

    pub fn parse(txt: []const u8) !Elf {
        var iter = std.mem.split(u8, txt, "-");
        const min = try std.fmt.parseInt(u32, iter.next().?, 10);
        const max = try std.fmt.parseInt(u32, iter.next().?, 10);
        return Elf{ .min = min, .max = max };
    }
};

test "parse elf" {
    const elf: Elf = try Elf.parse("2-4");
    try expectEqual(elf.min, 2);
    try expectEqual(elf.max, 4);

    const elf2: Elf = try Elf.parse("20-43");
    try expectEqual(elf2.min, 20);
    try expectEqual(elf2.max, 43);
}

fn parse_line(line: []const u8) ![2]Elf {
    var iter = std.mem.split(u8, line, ",");
    return [2]Elf{ try Elf.parse(iter.next().?), try Elf.parse(iter.next().?) };
}

test "parse line" {
    const result = try parse_line("6-6,4-6");
    try expectEqual(result[0].min, 6);
    try expectEqual(result[0].max, 6);
    try expectEqual(result[1].min, 4);
    try expectEqual(result[1].max, 6);
}

fn is_fully_contained(elves: [2]Elf) bool {
    return (elves[0].min <= elves[1].min and elves[0].max >= elves[1].max) or
        (elves[1].min <= elves[0].min and elves[1].max >= elves[0].max);
}
test "is_fully_contained" {
    try expectEqual(is_fully_contained(try parse_line("2-3,4-5")), false);
    try expectEqual(is_fully_contained(try parse_line("5-7,7-9")), false);
    try expectEqual(is_fully_contained(try parse_line("2-8,3-7")), true);
    try expectEqual(is_fully_contained(try parse_line("6-6,4-6")), true);
    try expectEqual(is_fully_contained(try parse_line("2-6,4-8")), false);
}

fn is_overlapping(elves: [2]Elf) bool {
    return (elves[0].min <= elves[1].max and elves[0].max >= elves[1].max) or (elves[1].min <= elves[0].max and elves[1].max >= elves[0].max);
}
test "is overlapping" {
    try expectEqual(is_overlapping(try parse_line("2-3,4-5")), false);
    try expectEqual(is_overlapping(try parse_line("5-7,7-9")), true);
    try expectEqual(is_overlapping(try parse_line("2-8,3-7")), true);
    try expectEqual(is_overlapping(try parse_line("6-6,4-6")), true);
    try expectEqual(is_overlapping(try parse_line("2-6,4-8")), true);
}

pub fn main() !void {
    var file = try File.new("input4.txt");
    var result: u64 = 0;
    while (try file.readline()) |line| {
        if (is_overlapping(try parse_line(line))) result += 1;
    }
    std.debug.print("Result: {d}\n", .{result});
}
