const std = @import("std");
const DS4 = @import("DS4Z.zig");

pub fn main() !void {
    const ds4 = DS4.Controller.init(0) catch {
        std.debug.print("\x1B[1;31mDevice Not Found\n", .{});
        return;
    };

    _ = ds4;

    while (true) {
        std.debug.print("\x1B[31m Bussy Bus \x1B[00m\n Sexy Suss\n", .{});
        //        try ds4.update();
        //        try ds4.printValues();
    }
}
