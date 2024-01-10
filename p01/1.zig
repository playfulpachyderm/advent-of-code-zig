const std = @import("std");

const Elf = struct {
    number: u16,
    calories: u64,
};
fn elf_cmp(_: void, e1: Elf, e2: Elf) bool {
    return e1.calories > e2.calories;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input1.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var elves = std.ArrayList(Elf).init(gpa.allocator());
    defer elves.deinit();

    // var max_elf_number: u16 = 0;
    // var max_elf_calories: u64 = 0;

    var elf_number: u16 = 1;
    var elf_calories: u64 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            // if (elf_calories > max_elf_calories) {
            //     std.debug.print("New record: elf {d} with {d} cals just beat elf {d} with {d} cals\n", .{ elf_number, elf_calories, max_elf_number, max_elf_calories });
            //     max_elf_calories = elf_calories;
            //     max_elf_number = elf_number;
            // }
            //std.debug.print("{d}\n", .{elf_calories});
            try elves.append(Elf{ .number = elf_number, .calories = elf_calories });
            elf_number += 1;
            elf_calories = 0;
            continue;
        }
        const cals = try std.fmt.parseInt(u64, line, 10);
        elf_calories += cals;
    }
    std.mem.sort(Elf, elves.items, {}, elf_cmp);
    //std.debug.print("Maximum elf number is {d} with {d} cals\n", .{ max_elf_number, max_elf_calories });
    var total: u64 = 0;
    for (0..3, elves.items[0..3]) |i, elf| {
        std.debug.print("Elf in {d}th place: elf {d} with {d} cals\n", .{ i, elf.number, elf.calories });
        total += elf.calories;
    }
    std.debug.print("Total: {d} cals\n", .{total});
}
