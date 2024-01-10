const std = @import("std");

const File = @import("utils.zig").File;

fn eval(round: [3]u8) u8 {
    const p1 = round[0];
    const p2 = round[2];
    const diff: i16 = @as(i16, p2) - 'X' + 'A' - @as(i16, p1);
    const victory_score: u8 = if (diff == 1 or diff == -2)
        6
    else if (diff == 0)
        3
    else
        0;
    return p2 - 'W' + victory_score;
}

fn eval2(round: [3]u8) u8 {
    const p1 = round[0] - 'A';
    const result: i16 = @as(i16, round[2]) - 'Y';
    const pre_p2 = p1 + result;
    const p2: u8 = if (pre_p2 == -1) 2 else if (pre_p2 == 3) 0 else @intCast(pre_p2);
    return @intCast((result + 1) * 3 + p2 + 1);
}

pub fn main() !void {
    //     var file = try std.fs.cwd().openFile("input2.txt", .{});
    //     defer file.close();
    //     var buf_reader = std.io.bufferedReader(file.reader());
    //     var in_stream = buf_reader.reader();
    //     var buf: [1024]u8 = undefined;

    var file = try File.new("input2.txt");
    var total: u64 = 0;
    //while (try in_stream.readUntilDelimiterOrEof(&buf, '\n') != null) {
    while (try file.readline()) |line| {
        total += eval2(line[0..3].*);
    }

    std.debug.print("Result: {d}\n", .{total});
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // var alloc = gpa.allocator();
    // var lut = std.StringHashMap(u8).init(alloc);

    // var buf: [3]u8 = undefined;
    // for ("ABC") |p1| {
    //     for ("XYZ") |p2| {
    //         const diff: i16 = @as(i16, p2) - 'X' + 'A' - @as(i16, p1);
    //         const victory_score: u8 = if (diff == 1 or diff == -2)
    //             6
    //         else if (diff == 0)
    //             3
    //         else
    //             0;
    //         buf[0] = p1;
    //         buf[1] = ' ';
    //         buf[2] = p2;
    //         std.debug.print("Inserting '{s}': {d}\n", .{ &buf, p2 - 'W' + victory_score });
    //         if (lut.get(&buf)) |val| {
    //             std.debug.print("Lut contains val for '{s}': {d}\n", .{ &buf, val });
    //         } else {
    //             std.debug.print("Missing key: {s}\n", .{&buf});
    //         }
    //         const existing_val = try lut.getOrPut(&buf);
    //         if (existing_val.found_existing) {
    //             std.debug.print("Found existing! '{d}'\n", .{existing_val.value_ptr.*});
    //         } else {
    //             existing_val.value_ptr.* = p2 - 'W' + victory_score;
    //         }
    //         if (lut.get(&buf)) |val| {
    //             std.debug.print("Lut contains val for '{s}': {d}\n", .{ &buf, val });
    //         } else {
    //             std.debug.print("Missing key: {s}\n", .{&buf});
    //         }
    //     }
    // }
}
