const std = @import("std");

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

const File = @import("utils.zig").File;

const Node = struct {
    name: []const u8,
    size: usize,
    contents: ?Entries,

    const Self = @This();
    const Entries = std.StringHashMap(Self);

    fn parse(alloc: std.mem.Allocator, input: []const u8) !Self {
        std.debug.print("Parsing: {s}\n", .{input});
        if (std.mem.eql(u8, input[0..3], "dir")) {
            return Node{ .name = try alloc.dupe(u8, input[4..]), .size = 0, .contents = null };
        }
        var iter = std.mem.splitScalar(u8, input, ' ');
        const size = iter.next() orelse unreachable;
        const name = iter.next() orelse unreachable;
        return Node{ .name = name, .size = try std.fmt.parseInt(usize, size, 10), .contents = null };
    }

    fn parse_ls(alloc: std.mem.Allocator, input: []const []const u8) !Entries {
        var ret: Entries = Entries.init(alloc);
        for (input) |line| {
            const node = try Self.parse(alloc, line);
            try ret.put(node.name, node);
        }
        return ret;
    }

    fn rsize(self: Self) usize {
        var total: usize = 0;
        if (self.contents) |contents| {
            var iter = contents.iterator();
            while (iter.next()) |mapentry| {
                total += mapentry.value_ptr.rsize();
            }
        } else {
            total += self.size;
        }
        return total;
    }
};

test "parse node" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const node1 = try Node.parse(arena.allocator(), "14848514 b.txt");
    try expect(std.mem.eql(u8, node1.name, "b.txt"));
    try expectEqual(node1.size, 14848514);
    try expectEqual(node1.rsize(), 14848514);
    try expectEqual(node1.contents, null);

    const node2 = try Node.parse(arena.allocator(), "dir bfjwtxt");
    try expect(std.mem.eql(u8, node2.name, "bfjwtxt"));
    try expectEqual(node2.size, 0);
    try expectEqual(node2.rsize(), 0);
}

test "parse ls output" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var nodes = try Node.parse_ls(arena.allocator(), &[_][]const u8{ "dir a", "14848514 b.txt", "8504156 c.dat", "dir d" });
    defer nodes.deinit();

    try expectEqual(nodes.count(), 4);
    try expect(std.mem.eql(u8, nodes.get("a").?.name, "a"));
    try expect(std.mem.eql(u8, nodes.get("b.txt").?.name, "b.txt"));
    try expectEqual(nodes.get("b.txt").?.size, 14848514);
}

const WorkingDir = struct {
    path: std.ArrayList([]const u8),
    root: Node,

    const Self = @This();

    fn init(alloc: std.mem.Allocator) Self {
        return Self{ .path = std.ArrayList([]const u8).init(alloc), .root = Node{ .name = "/", .size = 0, .contents = null } };
    }
    fn cd(self: *Self, dir: []const u8) !void {
        if (std.mem.eql(u8, dir, "..")) {
            // Remove the last item
            _ = self.path.pop();
        } else {
            try self.path.append(dir);
        }
    }
    fn cwd(self: *Self) *Node {
        var ret: *Node = &self.root;
        for (self.path.items) |dir| {
            ret = ret.contents.?.getPtr(dir).?;
        }
        return ret;
    }
    fn ls(self: *Self, entries: Node.Entries) void {
        self.cwd().*.contents = entries;
    }
};

test "working dir" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    var d: WorkingDir = WorkingDir.init(arena.allocator());
    try expect(std.mem.eql(u8, d.cwd().name, "/"));

    d.ls(try Node.parse_ls(arena.allocator(), &[_][]const u8{ "dir a", "14848514 b.txt", "8504156 c.dat", "dir d" }));
    try expectEqual(d.cwd().rsize(), 14848514 + 8504156);

    try d.cd("a");
    try expect(std.mem.eql(u8, d.cwd().name, "a"));

    try d.cd("..");
    try expect(std.mem.eql(u8, d.cwd().name, "/"));
    try d.cd("a");
    try expectEqual(d.cwd().rsize(), 0);

    d.ls(try Node.parse_ls(arena.allocator(), &[_][]const u8{ "dir e", "29116 f", "2557 g", "62596 h.lst" }));
    try expectEqual(d.cwd().rsize(), 29116 + 2557 + 62596);

    try d.cd("e");
    try expect(std.mem.eql(u8, d.cwd().name, "e"));

    d.path.clearAndFree();
    try expect(std.mem.eql(u8, d.cwd().name, "/"));
    try expectEqual(d.cwd().rsize(), 14848514 + 8504156 + 29116 + 2557 + 62596);
}

pub fn main() !void {
    var file = try File.new("input.txt");
    _ = try file.readline(); // Ignore the cd into "/"

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());

    var d: WorkingDir = WorkingDir.init(arena.allocator());
    var try_line = try file.readline();
    while (try_line) |line| {
        var iter = std.mem.tokenizeScalar(u8, line, ' ');
        _ = iter.next(); // Ignore "$"
        const cmd = iter.next().?;
        if (std.mem.eql(u8, cmd, "cd")) {
            try d.cd(iter.next().?);
            try_line = try file.readline(); // Go next line
            continue;
        } else if (std.mem.eql(u8, cmd, "ls")) {
            var list = std.ArrayList([]const u8).init(arena.allocator());
            while (true) {
                try_line = try file.readline();
                if (try_line == null or try_line.?[0] == '$') break;
                std.debug.print("Processing line: {s}\n", .{try_line.?});
                try list.append(try_line.?);
            }
            d.ls(try Node.parse_ls(arena.allocator(), list.items));
        }
    }
    d.path.clearAndFree();
    std.debug.print("Total size: {d}\n", .{d.cwd().rsize()});
}
