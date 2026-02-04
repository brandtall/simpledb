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

pub const Statement = struct {
    statementType: StatementTypes,
    RowToInsert: ?Row = null,
};

pub const COLUMN_EMAIL_LENGTH = 255;
pub const COLUMN_USERNAME_LENGTH = 255;

pub const Row = struct {
    username: [COLUMN_USERNAME_LENGTH]u8,
    email: [COLUMN_EMAIL_LENGTH]u8,
};

const StatementTypes = enum { StatementInsert, StatementSelect, StatementUnknown };
const PrepareResult = enum { PreparedSuccess, PreparedSyntaxError, PreparedUnknown };
const ExecuteResult = enum { ExecuteSuccess, ExecuteTableFull };

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
        if (command.len == 0) {
            continue;
        }
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
            var statement = Statement{ .statementType = StatementTypes.StatementUnknown };
            switch (prepareStatement(command, &statement)) {
                PrepareResult.PreparedSuccess => {},
                PrepareResult.PreparedSyntaxError => {
                    std.debug.print("Syntax error. Could not parse statement {s} \n", .{command});
                    continue;
                },
                PrepareResult.PreparedUnknown => {
                    std.debug.print("Unrecogonized statement command '{s}'. \n", .{command});
                    continue;
                },
            }
            _ = executeStatement(statement);
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

pub fn prepareStatement(command: []u8, statement: *Statement) PrepareResult {
    if (std.mem.eql(u8, command, "insert")) {
        statement.* = Statement{ .statementType = StatementTypes.StatementInsert, .RowToInsert = null };
        return PrepareResult.PreparedSuccess;
    } else if (std.mem.eql(u8, command, "select")) {
        statement.* = Statement{ .statementType = StatementTypes.StatementSelect, .RowToInsert = null };
        return PrepareResult.PreparedSuccess;
    }
    return PrepareResult.PreparedUnknown;
}
pub fn executeStatement(statement: Statement) ExecuteResult {
    switch (statement.statementType) {
        StatementTypes.StatementInsert => {
            std.debug.print("This is where we do an insert \n", .{});
            return ExecuteResult.ExecuteSuccess;
        },
        StatementTypes.StatementSelect => {
            std.debug.print("This is where we do a select \n", .{});
            return ExecuteResult.ExecuteSuccess;
        },
        StatementTypes.StatementUnknown => {
            std.debug.print("Error: Unknown statement type\n", .{});
            return ExecuteResult.ExecuteTableFull;
        },
    }
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
