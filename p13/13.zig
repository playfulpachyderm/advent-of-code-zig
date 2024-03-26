const std = @import("std");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const File = @import("utils.zig").File;

const Item = union(enum) {
    int: u32,
    list: std.ArrayList(Item),

    const ParseError = error{
        end_of_string_reached,
    };
    const ParseResult = struct { item: Item, chars_used: usize };
    fn parse(alloc: std.mem.Allocator, str: []const u8) !ParseResult {
        if ('0' <= str[0] and str[0] <= '9') {
            // Parse as an int
            return ParseResult{
                .item = Item{ .int = try std.fmt.parseInt(u32, str, 10) },
                .chars_used = str.len,
            };
        }
        // Otherwise, parse it as a list

        var ret = std.ArrayList(Item).init(alloc);
        var i: usize = 1; // Skip first char '['
        while (i < str.len) {
            switch (str[i]) {
                '[' => {
                    // Beginning of new nested list
                    const result = try Item.parse(alloc, str[i..str.len]);
                    try ret.append(result.item);
                    i += result.chars_used;
                },
                ']' => {
                    // End of this item.  Return the result
                    return ParseResult{ .item = Item{ .list = ret }, .chars_used = i + 1 };
                },
                ',' => {
                    // After consuming a [...] list, there could be a comma separating the next item.
                    // Do nothing just consume it
                    i += 1;
                },
                else => {
                    // It's a digit
                    var ii = i + 1;
                    while (str[ii] != ',' and str[ii] != ']') : (ii += 1) {} // Read until the end of the int
                    const result = try Item.parse(alloc, str[i..ii]);
                    try ret.append(result.item);
                    i += result.chars_used;
                    if (str[ii] == ',') {
                        // Skip the ','
                        i += 1;
                    }
                },
            }
        }
        return ParseError.end_of_string_reached;
    }
    fn deinit(self: Item) void {
        switch (self) {
            .int => {},
            .list => |l| {
                for (l.items) |item| {
                    item.deinit();
                }
                l.deinit();
            },
        }
    }
    // Return 2 if left is greater; 1 if they are equal; 0 if right is greater
    fn cmp(self: Item, other: Item) u8 {
        var buffer: [1000]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        const alloc = fba.allocator();

        return switch (self) {
            .int => |self_i| switch (other) {
                .int => |other_i| {
                    if (self_i > other_i)
                        return 2
                    else if (self_i == other_i)
                        return 1
                    else
                        return 0;
                },
                .list => self.as_list(alloc).cmp(other),
            },
            .list => |self_l| switch (other) {
                .int => self.cmp(other.as_list(alloc)),
                .list => |other_l| blk: {
                    var i: usize = 0;
                    while (i < self_l.items.len and i < other_l.items.len) : (i += 1) {
                        const val = self_l.items[i].cmp(other_l.items[i]);
                        if (val != 1) break :blk val;
                    }
                    return if (self_l.items.len > other_l.items.len) 2 else if (self_l.items.len == other_l.items.len) 1 else 0;
                },
            },
        };
    }
    fn as_list(self: Item, alloc: std.mem.Allocator) Item {
        return switch (self) {
            .list => self,
            .int => blk: {
                var tmplist = std.ArrayList(Item).init(alloc);
                tmplist.append(self) catch unreachable;
                break :blk Item{ .list = tmplist };
            },
        };
    }
};

test "parse single int" {
    var alloc = std.testing.allocator;

    const result = try Item.parse(alloc, "123");
    try expectEqual(result.chars_used, 3);
    try expectEqual(result.item.int, 123);
}
test "parse list of single int" {
    var alloc = std.testing.allocator;

    const result = try Item.parse(alloc, "[123]");
    try expectEqual(result.chars_used, 5);
    try expectEqual(result.item.list.items.len, 1);
    try expectEqual(result.item.list.items[0].int, 123);
    result.item.deinit();
}
test "parse list of 3 items" {
    var alloc = std.testing.allocator;

    const result = try Item.parse(alloc, "[123,234,3]");
    try expectEqual(result.chars_used, 11);
    try expectEqual(result.item.list.items.len, 3);
    try expectEqual(result.item.list.items[0].int, 123);
    try expectEqual(result.item.list.items[1].int, 234);
    try expectEqual(result.item.list.items[2].int, 3);
    result.item.deinit();
}
test "parse list with no items (empty)" {
    var alloc = std.testing.allocator;

    const result = try Item.parse(alloc, "[]");
    try expectEqual(result.chars_used, 2);
    try expectEqual(result.item.list.items.len, 0);
    result.item.deinit();
}
test "parse nested list" {
    var alloc = std.testing.allocator;

    const result = try Item.parse(alloc, "[[123]]");
    try expectEqual(result.chars_used, 7);
    try expectEqual(result.item.list.items.len, 1);
    try expectEqual(result.item.list.items[0].list.items.len, 1);
    try expectEqual(result.item.list.items[0].list.items[0].int, 123);
    result.item.deinit();
}
test "parse list of nested list and int" {
    var alloc = std.testing.allocator;

    const result = try Item.parse(alloc, "[[1],4]");
    try expectEqual(result.chars_used, 7);
    try expectEqual(result.item.list.items.len, 2);
    try expectEqual(result.item.list.items[0].list.items.len, 1);
    try expectEqual(result.item.list.items[0].list.items[0].int, 1);
    try expectEqual(result.item.list.items[1].int, 4);
    result.item.deinit();
}
test "parse nested empty lists" {
    var alloc = std.testing.allocator;

    const result = try Item.parse(alloc, "[[[]]]");
    try expectEqual(result.chars_used, 6);
    try expectEqual(result.item.list.items.len, 1);
    try expectEqual(result.item.list.items[0].list.items.len, 1);
    try expectEqual(result.item.list.items[0].list.items[0].list.items.len, 0);
    result.item.deinit();
}

// comparison tests

test "compare ints" {
    try expectEqual((Item{ .int = 1 }).cmp(Item{ .int = 2 }), 0);
    try expectEqual((Item{ .int = 2 }).cmp(Item{ .int = 2 }), 1);
    try expectEqual((Item{ .int = 5 }).cmp(Item{ .int = 2 }), 2);
}
test "compare lists" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    const test_case = struct {
        p1: []const u8,
        p2: []const u8,
        result: u8,
    };
    const cases: []const test_case = &[_]test_case{
        // Equal lengths
        test_case{ .p1 = "[1,2,3,4]", .p2 = "[1,2,2,4]", .result = 2 },
        test_case{ .p1 = "[1,2,3,4]", .p2 = "[1,2,3,4]", .result = 1 },
        test_case{ .p1 = "[1,2,3,4]", .p2 = "[1,2,4,4]", .result = 0 },
        // Unequal lengths
        test_case{ .p1 = "[1,2,3,4]", .p2 = "[1,2,2]", .result = 2 },
        test_case{ .p1 = "[1,2,3,4]", .p2 = "[1,2,4,5,6]", .result = 0 },
        // Longer list wins
        test_case{ .p1 = "[1,2,3,4]", .p2 = "[1,2,3]", .result = 2 },
        test_case{ .p1 = "[1,2,3,4]", .p2 = "[1,2,3,4,5,6]", .result = 0 },
        // Nested lists
        test_case{ .p1 = "[1,[2,5,6],3,4]", .p2 = "[1,[2,9],3,4,5,6]", .result = 0 },
        test_case{ .p1 = "[1,[2,10,6],3,4]", .p2 = "[1,[2,9],3,4,5,6]", .result = 2 },
        test_case{ .p1 = "[1,[2,[3,[4,[5,6,7]]]],8,9]", .p2 = "[1,[2,[3,[4,[5,6,0]]]],8,9]", .result = 2 },
        test_case{ .p1 = "[1,[2,[3,[4,[5,6,7]]]],8,9]", .p2 = "[1,[2,[3,[4,[5,6,7,[]]]]],8,9]", .result = 0 },
        // Int as list
        test_case{ .p1 = "[[1],[2,3,4]]", .p2 = "[[1],4]", .result = 0 },
        test_case{ .p1 = "[9]", .p2 = "[[8,7,6]]", .result = 2 },
        // Blanks??
        test_case{ .p1 = "[[[]]]", .p2 = "[[]]", .result = 2 },
    };
    for (cases) |case| {
        try expectEqual((try Item.parse(alloc, case.p1)).item.cmp((try Item.parse(alloc, case.p2)).item), case.result);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    var file = try File.new("input.txt");
    defer file.close();
    var i: usize = 1;
    var sum: usize = 0;

    const decoder1 = (try Item.parse(arena.allocator(), "[[2]]")).item;
    var i_d1: usize = 1;
    const decoder2 = (try Item.parse(arena.allocator(), "[[6]]")).item;
    var i_d2: usize = 2;
    while (try file.readline()) |line| {
        if (line.len == 0) continue;
        const p1 = (try Item.parse(arena.allocator(), line)).item;
        const p2 = (try Item.parse(arena.allocator(), (try file.readline()).?)).item;

        if (p1.cmp(p2) == 0) {
            sum += i;
        }

        if (p1.cmp(decoder1) == 0) {
            i_d1 += 1;
        }
        if (p2.cmp(decoder1) == 0) {
            i_d1 += 1;
        }
        if (p1.cmp(decoder2) == 0) {
            i_d2 += 1;
        }
        if (p2.cmp(decoder2) == 0) {
            i_d2 += 1;
        }

        i += 1;
    }
    std.debug.print("Sum: {d}\n", .{sum});
    std.debug.print("d1: {d}; d2: {d}; prod: {d}\n", .{ i_d1, i_d2, i_d1 * i_d2 });
}
