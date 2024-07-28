const std = @import("std");
const DS4 = @import("DS4Z.zig");

pub fn main() !void {
    const ds4 = DS4.Controller.init(0) catch {
        std.debug.print("\x1B[1;31mDevice Not Found\n", .{});
        return;
    };

    while (true) {
        _ = @constCast(&ds4).update() catch |err| switch (err) {
            DS4.UpdateError.unknown_handle => std.debug.print("Error No Known Handle: {d}, Data Dump: {s}\n", .{ ds4.data[7], ds4.data }),
            DS4.UpdateError.unexpected_data => std.debug.print("Error, Unknown Data Type: {d}, Unknown Data: {s}\n", .{ ds4.data[6], ds4.data }),
            else => std.debug.print("Controller {d} is disconnected", .{ds4.id}),
            //break :p;
        };
        try printValues(ds4);
    }
}

const green = "\x1B[32m";
const red = "\x1B[31m";
const reset = "\x1B[00m";

// Helper Functions ===
inline fn colour(input: u8) [5:0]u8 {
    return cv(input != 0);
}

inline fn cv(v: bool) [5:0]u8 {
    return if (v) green.* else red.*;
}

inline fn wrapper(enum_or_tagged_union: anytype) usize {
    return @intFromEnum(enum_or_tagged_union);
}
const ief = wrapper;
/// ====
pub fn prep_display() []u8 {
    const buttons = [_][]const u8{
        "Square",
        "Cross",
        "Triangle",
        "Circle",
        "Share",
        "Options",
        "L1",
        "R1",
        "L3",
        "R3",
    };

    const triggers = [_][]const u8{
        "L2:",
        "R2:",
        "Left Stick X:",
        "Left Stick Y:",
        "Right Stick X:",
        "Right Stick Y:",
    };

    var display_buffer: []u8 = @constCast("\x1B[2J");

    for (buttons[0..]) |button|
        display_buffer = @constCast(display_buffer ++ "{s}" ++ button ++ "\x1B[0m\n");

    display_buffer = @constCast(display_buffer ++ "     {s}Up\x1B[0m\n{s}Left\x1B[0m    {s}Right\x1B[0m\n    {s}Down\x1B[0m\n");

    for (triggers[0..]) |trigger|
        display_buffer = @constCast(display_buffer ++ "{s}" ++ trigger ++ "{d}\x1B[0m\n");
    return display_buffer;
}

const display: []u8 = prep_display();

const Bindings = DS4.Bindings;
const colours = DS4.colours;

pub fn printValues(self: DS4.Controller) !void {
    if (!self.updated) return;

    std.debug.print(display, .{
        colour(self.buttons[ief(Bindings.Square)]),
        colour(self.buttons[ief(Bindings.Cross)]),
        colour(self.buttons[ief(Bindings.Triangle)]),
        colour(self.buttons[ief(Bindings.Circle)]),
        colour(self.buttons[ief(Bindings.Share)]),
        colour(self.buttons[ief(Bindings.Options)]),
        colour(self.buttons[ief(Bindings.L1)]),
        colour(self.buttons[ief(Bindings.R1)]),
        colour(self.buttons[ief(Bindings.L3)]),
        colour(self.buttons[ief(Bindings.R3)]),

        cv(self.buttons[ief(Bindings.DPAD_Vert)] == 0xFF),
        cv(self.buttons[ief(Bindings.DPAD_Hori)] == 0xFF),
        cv(self.buttons[ief(Bindings.DPAD_Hori)] == 1),
        cv(self.buttons[ief(Bindings.DPAD_Vert)] == 1),

        colour(self.buttons[ief(Bindings.L2)]),
        self.buttons[ief(Bindings.L2)],

        colour(self.buttons[ief(Bindings.R2)]),
        self.buttons[ief(Bindings.R2)],

        colour(self.buttons[ief(Bindings.LStick_H)]),
        @as(i8, @bitCast(self.buttons[ief(Bindings.LStick_H)])),

        colour(self.buttons[ief(Bindings.LStick_V)]),
        @as(i8, @bitCast(self.buttons[ief(Bindings.LStick_V)])),

        colour(self.buttons[ief(Bindings.RStick_H)]),
        @as(i8, @bitCast(self.buttons[ief(Bindings.RStick_H)])),

        colour(self.buttons[ief(Bindings.RStick_V)]),
        @as(i8, @bitCast(self.buttons[ief(Bindings.RStick_V)])),
    });
}
