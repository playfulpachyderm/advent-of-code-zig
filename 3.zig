const std = @import("std");
const File = @import("utils.zig").File;

const expectEqual = std.testing.expectEqual;

fn get_position(chr: u8) u8 {
    //  std.debug.print("{c}", .{chr});
    if (chr >= 'A' and chr <= 'Z') return chr - 'A' + 26;
    if (chr >= 'a' and chr <= 'z') return chr - 'a';
    std.debug.print("Unknown char: '{c}' ({d})\n", .{ chr, chr });
    unreachable;
}

test "get_position basic tests" {
    try expectEqual(get_position('p') + 1, 16);
    try expectEqual(get_position('L') + 1, 38);
    try expectEqual(get_position('P') + 1, 42);
}

const Itemset = [52]bool;

fn comm(sets: []const Itemset) u8 {
    for (0..52) |i| {
        const is_in_all_sets = for (sets) |set| {
            if (!set[i]) break false;
        } else true;
        if (is_in_all_sets) return @intCast(i);
    }
    unreachable;
}

test "comm" {
    var itemset1: Itemset = [_]bool{false} ** 52;
    var itemset2: Itemset = [_]bool{false} ** 52;
    var itemset3: Itemset = [_]bool{false} ** 52;
    itemset1[3] = true;
    itemset1[10] = true;
    itemset2[4] = true;
    itemset2[10] = true;
    itemset3[10] = true;

    try expectEqual(comm(&[_]Itemset{ itemset1, itemset2, itemset3 }), 10);
}

fn get_uniq_items(line: []const u8) Itemset {
    var flags: Itemset = [_]bool{false} ** 52;
    for (0..line.len) |i| {
        flags[get_position(line[i])] = true;
    }
    //    std.debug.print("Codes: {any}\n", .{flags});

    return flags;
}
fn process_line(line: []const u8) u8 {
    const items1 = get_uniq_items(line[0 .. line.len / 2]);
    const items2 = get_uniq_items(line[line.len / 2 .. line.len]);
    return comm(&[_]Itemset{ items1, items2 }) + 1;
}

test "process_line cases" {
    try expectEqual(process_line("vJrwpWtwJgWrhcsFMMfFFhFp"), 16);
    //i//try expectEqual(process_line("rrhp"), 16);
}

fn process_line2(lines: [3]Itemset) u8 {
    return comm(&lines) + 1; //[_]Itemset{ get_uniq_items(lines[0]), get_uniq_items(lines[1]), get_uniq_items(lines[2]) }) + 1;
}

//fn process_group(file: *File) u8 {
//
//}

test "process_line2" {
    const lines1: [3][]const u8 = .{ "vJrwpWtwJgWrhcsFMMfFFhFp", "jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL", "PmmdzqPrVvPwwTWBwg" };
    try expectEqual(process_line2(lines1), 18);
    const lines2: [3][]const u8 = .{ "wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn", "ttgJtRGJQctTZtZT", "CrZsJsPPZsGzwwsLwLmpwMDw" };
    try expectEqual(process_line2(lines2), 52);
}

pub fn main() !void {
    var file = try File.new("input3.txt");
    var total: u64 = 0;
    var lines: [3]Itemset = undefined;
    while (try file.readline()) |line| {
        lines[0] = get_uniq_items(line);
        lines[1] = get_uniq_items((try file.readline()).?);
        lines[2] = get_uniq_items((try file.readline()).?);
        total += process_line2(lines);
    }
    std.debug.print("Total: {d}\n", .{total});
}
