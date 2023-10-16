const std = @import("std");

const File = @import("utils.zig").File;

const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

const Box = struct {
    letter: u8,
    next: ?*Box = null,
};

const Stack = struct {
    const Error = error{
        StackIsEmpty,
    };
    top: ?*Box = null,

    fn pop(self: *Stack) ?*Box {
        const result = self.top;
        if (result) |r| {
            self.top = r.next;
        }
        return result;
    }

    fn push(self: *Stack, _box: *Box) void {
        var box = _box;
        box.next = self.top;
        self.top = box;
    }

    fn parse_stacks(allocator: std.mem.Allocator, input: []const []const u8) []Stack {
        var ret: []Stack = undefined;

        // Initialize the result with the right amount of stacks
        var stack_nums_iter = std.mem.splitBackwardsAny(u8, input[input.len - 1], " ");
        while (stack_nums_iter.next()) |num| {
            if (std.fmt.parseInt(u8, num, 10) catch null) |result| {
                ret = allocator.alloc(Stack, result) catch unreachable;
                break;
            }
        }
        for (ret) |*stack| {
            stack.top = null;
        }

        // Parse the rows, from bottom to top
        var row_num: usize = input.len;
        while (row_num > 0) : (row_num -= 1) {
            const row: []const u8 = input[row_num - 1];
            std.debug.print("Row: {s}\n", .{row});
            for (0..ret.len) |i| {
                const chr: u8 = row[i * 4 + 1];
                std.debug.print("Checking char {c} for i={d}\n", .{ chr, i });
                if (chr >= 'A' and chr <= 'Z') {
                    std.debug.print("Pushing char {c}\n", .{chr});
                    const newbox: *Box = allocator.create(Box) catch unreachable;
                    newbox.* = .{ .letter = chr, .next = null };
                    ret[i].push(newbox);
                }
            }
        }
        return ret;
    }

    fn deinit(self: *Stack, alloc: std.mem.Allocator) void {
        while (self.top) |box| {
            self.top = box.next;
            alloc.destroy(box);
        }
    }
    fn print(self: *const Stack) void {
        std.debug.print("--Stack--\n", .{});
        var top = self.top;
        while (top) |box| {
            std.debug.print("Box: {c}; next is ", .{box.letter});
            if (box.next == null) {
                std.debug.print("null\n", .{});
            } else {
                std.debug.print("not null\n", .{});
            }
            top = box.next;
        }
    }
};

test "stack push and pop" {
    var stack: Stack = Stack{ .top = null };
    try expectEqual(stack.top, null);

    const alloc = std.testing.allocator;
    const box1 = try alloc.create(Box);
    defer alloc.destroy(box1);
    box1.* = .{ .letter = 'J' };
    const box2 = try alloc.create(Box);
    defer alloc.destroy(box2);
    box2.* = .{ .letter = 'K' };

    try expect(stack.top == null);
    stack.push(box1);
    try expect(stack.top != null);
    try expectEqual(stack.top.?.letter, 'J');
    stack.push(box2);
    try expect(stack.top != null);
    try expectEqual(stack.top.?.letter, 'K');

    const trytop = stack.pop();
    try expect(trytop != null);
    try expect(trytop.?.letter == 'K');
    const trytop2 = stack.pop();
    try expect(trytop2 != null);
    try expect(trytop2.?.letter == 'J');
    try expect(stack.top == null);

    const trytop3 = stack.pop();
    try expect(trytop3 == null);
}

fn move(from: *Stack, to: *Stack) void {
    const tmp: ?*Box = from.pop();
    if (tmp) |box| {
        to.push(box);
    }
}

test "move" {
    var stack1: Stack = Stack{};
    var stack2: Stack = Stack{};

    const alloc = std.testing.allocator;
    const box1 = try alloc.create(Box);
    defer alloc.destroy(box1);
    box1.* = .{ .letter = 'J' };

    stack1.push(box1);
    move(&stack1, &stack2);
    try expect(stack1.top == null);
    try expect(stack2.top != null);
    try expect(stack2.top.?.letter == 'J');
}

test "parse stacks" {
    const alloc = std.testing.allocator;
    const input: []const []const u8 = &[_][]const u8{ "    [D]    ", "[N] [C]    ", "[Z] [M] [P]", " 1   2   3 " };
    var stacks: []Stack = Stack.parse_stacks(alloc, input);
    defer {
        for (stacks, 0..) |*stack, i| {
            std.debug.print("\nDeallocating stack #{d}\n", .{i});
            stack.print();
            stack.deinit(alloc);
        }
        alloc.free(stacks);
    }
    try expectEqual(stacks.len, 3);
    stacks[0].print();
    stacks[1].print();
    stacks[2].print();
    try expectEqual(stacks[0].top.?.letter, 'N');
    try expectEqual(stacks[0].top.?.next.?.letter, 'Z');
    try expectEqual(stacks[1].top.?.letter, 'D');
    try expectEqual(stacks[1].top.?.next.?.letter, 'C');
    try expectEqual(stacks[1].top.?.next.?.next.?.letter, 'M');
    try expectEqual(stacks[2].top.?.letter, 'P');
}

const Move = struct {
    from: u8,
    to: u8,
    count: u8,
};

fn parse_move_line(line: []const u8) !Move {
    var iter = std.mem.splitAny(u8, line, " ");
    var ret: Move = Move{ .from = 0, .to = 0, .count = 0 };
    _ = iter.next(); // "move"
    ret.count = try std.fmt.parseInt(u8, iter.next() orelse unreachable, 10);
    _ = iter.next(); // "from"
    ret.from = try std.fmt.parseInt(u8, iter.next() orelse unreachable, 10);
    _ = iter.next();
    ret.to = try std.fmt.parseInt(u8, iter.next() orelse unreachable, 10);
    return ret;
}
test "parse move line" {
    const move1 = try parse_move_line("move 5 from 3 to 9");
    try expectEqual(move1.count, 5);
    try expectEqual(move1.from, 3);
    try expectEqual(move1.to, 9);
}

pub fn main() !void {
    var file = try File.new("input.txt");
    var _alloc = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = _alloc.allocator();

    var stack_lines = std.ArrayList([]const u8).init(alloc);
    defer {
        for (stack_lines.items) |item| {
            alloc.free(item);
        }
        stack_lines.deinit();
    }
    while (try file.readline()) |line| {
        if (line.len == 0) {
            break;
        }
        try stack_lines.append(try alloc.dupe(u8, line));
    }
    for (stack_lines.items) |line| {
        std.debug.print("Line: {s}\n", .{line});
    }
    var stacks = Stack.parse_stacks(alloc, stack_lines.items);
    std.debug.print("There are {d} stacks\n", .{stacks.len});
    for (stacks) |stack| {
        stack.print();
    }

    while (try file.readline()) |line| {
        const mv = try parse_move_line(line);
        var tmp_stack: Stack = Stack{};
        for (0..mv.count) |_| {
            move(&stacks[mv.from - 1], &tmp_stack);
        }
        while (tmp_stack.top != null) {
            move(&tmp_stack, &stacks[mv.to - 1]);
        }
    }
    for (stacks) |s| {
        std.debug.print("{c}", .{s.top.?.letter});
    }
    std.debug.print("\n", .{});
}
