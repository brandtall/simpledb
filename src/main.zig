const std = @import("std");
const Allocator = std.mem.Allocator;

pub const InputBuffer = struct {

    buffer: []u8,
    input_length: usize,

    pub fn init(allocator: Allocator) !*InputBuffer{
        const self = try allocator.create(InputBuffer);
        const backing_memory = try allocator.alloc(u8, 4096);
        self.* = .{
            .buffer = backing_memory,
            .input_length = 0,
        };

        return self;
    }

    pub fn deinit(self: *InputBuffer, allocator: Allocator) void{
        allocator.free(self.buffer);
        allocator.destroy(self);
    }

};

const InputError = error {
    ErrorBuffer,
    BufferOverflow,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const inputBuffer = try InputBuffer.init(allocator);

    while(true) {
        printPrompt();
        try readInput(inputBuffer);
    }    
}

pub fn printPrompt() void {
    std.debug.print("simpledb> ", .{});
}

pub fn readInput(inputBuffer: *InputBuffer) !void {

    var stdin_buf: [4096]u8 = undefined;
    var stdin_impl = std.fs.File.stdin().reader(&stdin_buf);
    while (stdin_impl.takeByte()) |char| {
        
    if (try stdin_impl.readUntilDelimiterOrEof(inputBuffer.buffer, '\n')) |line| {
        if (line.len > 0 and line[line.len - 1] == '\r') {
             inputBuffer.input_length = line.len - 1;
        } else {
             inputBuffer.input_length = line.len;
        }
    }
    else {
    }
}


