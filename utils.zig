const std = @import("std");

pub const File = struct {
    stdfile: std.fs.File = undefined,
    buf_reader: std.io.BufferedReader(4096, std.fs.File.Reader) = undefined,
    in_stream: std.io.BufferedReader(4096, std.fs.File.Reader).Reader = undefined,
    buf: [5000]u8 = undefined,

    pub fn new(filename: []const u8) !File {
        var ret = File{};
        ret.stdfile = try std.fs.cwd().openFile(filename, .{});
        ret.buf_reader = std.io.bufferedReader(ret.stdfile.reader());
        ret.in_stream = ret.buf_reader.reader();
        return ret;
    }
    pub fn readline(self: *File) !?[]u8 {
        return try self.in_stream.readUntilDelimiterOrEof(&self.buf, '\n');
    }
    pub fn close(self: File) void {
        self.stdfile.close();
    }
};
