const std = @import("std");
const DS4 = @import("DS4Z.zig");

pub fn main() !void {
    var ds4 = DS4.Controller.init(0) catch {
        std.debug.print("\x1B[1;31mDevice Not Found\n", .{});
        return;
    };

    while (true) {
        try ds4.update();
        //try ds4.PrintState();
    }
}
