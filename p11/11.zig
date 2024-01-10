const std = @import("std");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const File = @import("utils.zig").File;

const Monkey = struct {
    items: std.ArrayList(u64),
    operator: Operator,
    operand: Operand,
    test_divisor: u64,
    monkey_true: usize,
    monkey_false: usize,

    num_items_inspected: usize = 0,

    const Operator = enum {
        plus,
        times,
    };
    const Operand = union(enum) {
        number: u64,
        self: void,
    };

    fn parse(alloc: std.mem.Allocator, txt: []const u8) Monkey {
        var lines = std.mem.splitScalar(u8, txt, '\n');
        _ = lines.next(); // First line is monkey number, skip
        var items = std.mem.splitSequence(u8, lines.next().?[18..], ", "); // Second line: items
        var itemsList = std.ArrayList(u64).init(alloc);
        while (items.next()) |item| {
            itemsList.append(std.fmt.parseInt(u64, item, 10) catch unreachable) catch unreachable;
        }
        const operation_line = lines.next().?;
        const operator = switch (operation_line[23]) {
            '+' => Operator.plus,
            '*' => Operator.times,
            else => unreachable,
        };
        const operand = if (std.mem.eql(u8, operation_line[25..], "old"))
            Operand{ .self = void{} }
        else
            Operand{ .number = std.fmt.parseInt(u64, operation_line[25..], 10) catch unreachable };
        const test_divisor = std.fmt.parseInt(u64, lines.next().?[21..], 10) catch unreachable;

        const monkey_true = std.fmt.parseInt(u64, lines.next().?[29..], 10) catch unreachable;
        const monkey_false = std.fmt.parseInt(u64, lines.next().?[30..], 10) catch unreachable;
        return Monkey{
            .items = itemsList,
            .operator = operator,
            .operand = operand,
            .test_divisor = test_divisor,
            .monkey_true = monkey_true,
            .monkey_false = monkey_false,
        };
    }
    fn inspect(m: *Monkey, item: u64) u64 {
        m.num_items_inspected += 1;
        return switch (m.operand) {
            .number => |val| switch (m.operator) {
                .plus => val + item,
                .times => val * item,
            },
            .self => switch (m.operator) {
                .plus => item + item,
                .times => item * item,
            },
        }; // / 3;
    }
    fn throw(m: Monkey, item: u64) usize {
        return if (@mod(item, m.test_divisor) == 0)
            m.monkey_true
        else
            m.monkey_false;
    }
};

test "parse monkey" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const txt =
        \\Monkey 0:
        \\  Starting items: 89, 73, 66, 57, 64, 80
        \\  Operation: new = old * 3
        \\  Test: divisible by 13
        \\    If true: throw to monkey 6
        \\    If false: throw to monkey 2
    ;
    const m = Monkey.parse(arena.allocator(), txt);
    defer m.items.deinit();
    try expectEqual(m.items.items.len, 6);
    try expectEqualSlices(u64, m.items.items, &[_]u64{ 89, 73, 66, 57, 64, 80 });
    try expectEqual(m.operator, Monkey.Operator.times);
    try expectEqual(m.operand, Monkey.Operand{ .number = 3 });
    try expectEqual(m.test_divisor, 13);
    try expectEqual(m.monkey_true, 6);
    try expectEqual(m.monkey_false, 2);
}

test "inspect" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const txt =
        \\Monkey 0:
        \\  Starting items: 89, 73, 66, 57, 64, 80
        \\  Operation: new = old * old
        \\  Test: divisible by 13
        \\    If true: throw to monkey 6
        \\    If false: throw to monkey 2
    ;
    const m = Monkey.parse(arena.allocator(), txt);
    defer m.items.deinit();

    try expectEqual(m.inspect(40), 533);
    try expectEqual(m.throw(533), 6);
    try expectEqual(m.throw(534), 2);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());

    var file = try std.fs.cwd().openFile("input.txt", .{});
    var buff = try arena.allocator().alloc(u8, (try file.stat()).size);
    _ = try file.readAll(buff);

    var _monkeys = std.ArrayList(Monkey).init(arena.allocator());
    defer _monkeys.deinit();
    var blocks = std.mem.splitSequence(u8, std.mem.trim(u8, buff, "\n"), "\n\n");
    while (blocks.next()) |blk| {
        try _monkeys.append(Monkey.parse(arena.allocator(), blk));
    }
    var monkeys = _monkeys.items;
    std.debug.print("Monkeys: {d}\n", .{monkeys.len});

    var fake_lcd: u64 = 1;
    for (monkeys) |m| {
        fake_lcd *= m.test_divisor;
    }
    for (0..10000) |_| {
        for (monkeys) |*m| {
            for (m.items.items) |item| {
                const result = @mod(m.inspect(item), fake_lcd);
                const target = m.throw(result);
                try monkeys[target].items.append(result);
            }
            m.items.clearAndFree();
        }
    }

    for (0.., monkeys) |i, m| {
        std.debug.print("Monkey {d}: ", .{i});
        for (m.items.items) |item| {
            std.debug.print("{d}, ", .{item});
        }
        std.debug.print("\n", .{});
    }

    for (0.., monkeys) |i, m| {
        std.debug.print("Monkey {d}: {d} items\n", .{ i, m.num_items_inspected });
    }
}
