const std = @import("std");
const Allocator = std.mem.Allocator;

pub const InputBuffer = struct {
    buffer: []u8,
    input_length: usize,

    pub fn init(allocator: Allocator) !*InputBuffer {
        const self = try allocator.create(InputBuffer);
        const backing_memory = try allocator.alloc(u8, 4096);
        self.* = .{
            .buffer = backing_memory,
            .input_length = 0,
        };

        return self;
    }

    pub fn deinit(self: *InputBuffer, allocator: Allocator) void {
        allocator.free(self.buffer);
        allocator.destroy(self);
    }
};

const StatementTypes = enum { StatementInsert, StatementSelect, StatementUnknown };

const MetaCommands = enum { MetaCommandExit, MetaCommandUnknown };
const InputError = error{
    ErrorBuffer,
    BufferOverflow,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const inputBuffer = try InputBuffer.init(allocator);

    while (true) {
        printPrompt();
        try readInput(inputBuffer);
        const command = inputBuffer.buffer[0..inputBuffer.input_length];
        if (command[0] == '.') {
            switch (doMetaCommand(command)) {
                MetaCommands.MetaCommandExit => {
                    inputBuffer.deinit(allocator);
                    break;
                },
                MetaCommands.MetaCommandUnknown => {
                    continue;
                },
            }
        } else {
            switch (prepareStatement(command)) {
                StatementTypes.StatementInsert => {
                    std.debug.print("This is where we do an insert \n", .{});
                    continue;
                },
                StatementTypes.StatementSelect => {
                    std.debug.print("This is where we do a select \n", .{});
                    continue;
                },
                StatementTypes.StatementUnknown => {
                    continue;
                },
            }
        }
    }
}

pub fn doMetaCommand(command: []u8) MetaCommands {
    if (std.mem.eql(u8, command, ".exit")) {
        return MetaCommands.MetaCommandExit;
    } else {
        std.debug.print("Unrecogonized metacommand '{s}'. \n", .{command});
        return MetaCommands.MetaCommandUnknown;
    }
}

pub fn prepareStatement(command: []u8) StatementTypes {
    if (std.mem.eql(u8, command, "insert")) {
        return StatementTypes.StatementInsert;
    } else if (std.mem.eql(u8, command, "select")) {
        return StatementTypes.StatementSelect;
    }
    std.debug.print("Unrecogonized statement command '{s}'. \n", .{command});
    return StatementTypes.StatementUnknown;
}

pub fn printPrompt() void {
    std.debug.print("simpledb> ", .{});
}

pub fn readInput(inputBuffer: *InputBuffer) !void {
    var stdin_buf: [4096]u8 = undefined;
    var stdin_impl = std.fs.File.stdin().reader(&stdin_buf);
    const stdin: *std.io.Reader = &stdin_impl.interface;
    const line = try stdin.takeDelimiterExclusive('\n');
    inputBuffer.input_length = line.len;
    @memcpy(inputBuffer.buffer[0..inputBuffer.input_length], line[0..inputBuffer.input_length]);
}
