const std = @import("std");
const DS4 = @import("DS4Z.zig");

pub fn main() !void {
    var ds4 = DS4.Controller.init("/dev/input/js0") catch {
        std.debug.print("Device Not Found\n", .{});
        return;
    };
    try ds4.Update();
}
