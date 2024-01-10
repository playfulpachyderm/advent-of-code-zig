const std = @import("std");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

const File = @import("utils.zig").File;

const Board = struct {
    tail_positions: PositionSet,
    H: Coords = Coords{ .x = 0, .y = 0 },
    T: Coords = Coords{ .x = 0, .y = 0 },

    const PositionSet = std.AutoHashMap(Coords, void);

    const Coords = struct {
        x: i32,
        y: i32,
    };

    const Direction = enum {
        up,
        down,
        right,
        left,
    };

    fn init(alloc: std.mem.Allocator) Board {
        var ret = Board{ .tail_positions = PositionSet.init(alloc) };
        ret.tail_positions.put(ret.T, void{}) catch unreachable;
        return ret;
    }
    fn deinit(self: *Board) void {
        self.tail_positions.deinit();
    }

    fn move(self: *Board, direction: Direction, n: usize) void {
        for (0..n) |_| {
            switch (direction) {
                .up => {
                    self.H.y += 1;
                    if (self.H.y > self.T.y + 1) {
                        self.T.x = self.H.x;
                        self.T.y = self.H.y - 1;
                    }
                },
                .down => {
                    self.H.y -= 1;
                    if (self.H.y < self.T.y - 1) {
                        self.T.x = self.H.x;
                        self.T.y = self.H.y + 1;
                    }
                },
                .right => {
                    self.H.x += 1;
                    if (self.H.x > self.T.x + 1) {
                        self.T.y = self.H.y;
                        self.T.x = self.H.x - 1;
                    }
                },
                .left => {
                    self.H.x -= 1;
                    if (self.H.x < self.T.x - 1) {
                        self.T.y = self.H.y;
                        self.T.x = self.H.x + 1;
                    }
                },
            }
            self.tail_positions.put(self.T, void{}) catch unreachable;
        }
    }
};

test "move" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    var board = Board.init(arena.allocator());
    defer board.deinit();

    board.move(.right, 4);
    try expectEqual(board.tail_positions.count(), 4);
    try expect(board.tail_positions.contains(Board.Coords{ .x = 0, .y = 0 }));
    try expect(board.tail_positions.contains(Board.Coords{ .x = 1, .y = 0 }));
    try expect(board.tail_positions.contains(Board.Coords{ .x = 2, .y = 0 }));
    try expect(board.tail_positions.contains(Board.Coords{ .x = 3, .y = 0 }));
    try expect(!board.tail_positions.contains(Board.Coords{ .x = 3, .y = 1 }));
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());

    var board = Board.init(arena.allocator());
    defer board.deinit();

    var file = try File.new("input.txt");
    while (try file.readline()) |line| {
        const n = try std.fmt.parseInt(usize, line[2..], 10);
        board.move(
            switch (line[0]) {
                'R' => .right,
                'L' => .left,
                'U' => .up,
                'D' => .down,
                else => unreachable,
            },
            n,
        );
    }
    std.debug.print("Tail positions: {d}\n", .{board.tail_positions.count()});
}
