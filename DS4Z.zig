const std = @import("std");

const Bindings = enum(u8) {
    Cross,
    Circle,
    Triangle,
    Square,
    L1,
    R1, //5

    Share = 8,
    Options = 9,

    //    PSN = 10, // NO IDEA IF WE CAN GET THIS
    L3 = 11,
    R3 = 12,

    LStick_H = 13,
    LStick_V = 14,
    RStick_H = 15,
    RStick_V = 16,

    L2 = 17,
    R2 = 20,

    DPAD_Hori = 18,
    DPAD_Vert = 19,
};

const green = "\x1B[32m";
const red = "\x1B[31m";
const reset = "\x1B[0m";

const pressed = 1;

const touchpad = struct { click: u8, touch: u8, coordinates: [2]u8 };

pub const Controller = struct {
    buttons: [21]u8,
    in: std.fs.File,
    data: [63]u8,
    updated: bool,
    id: u8,

    pub fn init(idx: u8) !Controller {
        var path = "/dev/input/js0".*;
        path[path.len - 1] = std.fmt.digitToChar(idx, std.fmt.Case.lower);
        return Controller{
            .buttons = [_]u8{0} ** 21,
            .data = undefined,
            .updated = false,
            .id = idx,
            .in = try std.fs.openFileAbsolute(&path, .{}),
        };
    }

    fn ax(data: u8) u8 {
        return @divTrunc(@as(i8, @bitCast(data)), 16);
    }

    pub fn update(self: *Controller) !void {
        const bytes_read = try self.in.read(@constCast(&self.data));
        if (bytes_read == 1) {
            self.updated = false;
            return;
        }
        self.updated = true;
        // std.debug.print("Bytes Read: {d}\n", .{bytes_read});

        switch (self.data[6]) { // NOTE: Unknown Cases [2,5,8,12-255]
            1 => self.buttons[self.data[7]] = self.data[4], // most buttons
            2 => {
                switch (self.data[7]) {
                    6, 7 => { // DPAD Horizontal & Vertical
                        self.buttons[self.data[7] + 12] = switch (std.mem.bytesAsValue(u16, self.data[4..6]).*) {
                            0x7FFF => 1, // DPAD_RIGHT & DOWN
                            0x8001 => 0xFF, // DPAD_LEFT & UP
                            else => 0,
                        };
                    },
                    2, 5 => { // L2 & R2 // 6 & 7 are the inputs that store the [0,1] values of this
                        self.buttons[self.data[7] + 15] = @as(u8, @bitCast(ax(self.data[5]) + 8));
                        //self.buttons[self.data[7] + 15] = self.data[5];
                    },
                    0, 1 => { // L Stick Hori & Vert
                        self.buttons[self.data[7] + 13] = @as(u8, @bitCast(ax(self.data[5])));
                    },
                    3, 4 => { // R Stick Hori & Vert
                        self.buttons[self.data[7] + 12] = @as(u8, @bitCast(ax(self.data[5])));
                    },

                    else => std.debug.print("Error No Known Handle: {d}, Data Dump: {s}\n", .{ self.data[7], self.data }),
                }
            },
            else => std.debug.print("Error, Unknown Data Type: {d}, Unknown Data: {s}\n", .{ self.data[6], self.data }),
        }
    }

    // Helper Functions ===
    inline fn colour(input: u8) [5:0]u8 {
        return if (input != 0) green else red;
    }
    inline fn wrapper(enum_or_tagged_union: anytype) usize {
        return @intFromEnum(enum_or_tagged_union);
    }
    const ief = wrapper;
    /// ====
    pub fn printValues(self: Controller) !void {
        const display = undefined;
        comptime {
            const buttons = [_][]u8{
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

            const triggers = [_][]u8{
                "L2:",
                "R2:",
                "Left Stick X:",
                "Left Stick Y:",
                "Right Stick X:",
                "Right Stick Y:",
            };

            const display_buffer = "";

            for (buttons[0..]) |i|
                display_buffer = display_buffer ++ "{s}" ++ buttons[i] ++ "{s}\n";

            display_buffer = display_buffer ++ "{s}Up{s}\n{s}Left{s}    {s}Right{s}\n{s}Down{s}\n";

            for (triggers[0..]) |i|
                display_buffer = display_buffer ++ "{s}" ++ triggers[i] ++ "{d}{s}\n";
            display = display_buffer;
        }

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
            colour(self.buttons[ief(Bindings.DPAD_Hori)]),
            colour(self.buttons[ief(Bindings.Left)]),
            colour(self.buttons[ief(Bindings.Right)]),
            colour(self.buttons[ief(Bindings.Down)]),

            colour(self.buttons[ief(Bindings.Up)]),
            colour(self.buttons[ief(Bindings.Down)]),
            colour(self.buttons[ief(Bindings.Up)]),
            colour(self.buttons[ief(Bindings.Up)]),
            colour(self.buttons[ief(Bindings.Up)]),
            colour(self.buttons[ief(Bindings.Up)]),
        });

        // std.fmt.format(std.io.getStdOut().writer(), "", .{})

        if (!self.updated) return;
        std.debug.print("{s}Square{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.Square)] == pressed) green else red, reset });
        std.debug.print("{s}Cross{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.Cross)] == pressed) green else red, reset });
        std.debug.print("{s}Triangle{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.Triangle)] == pressed) green else red, reset });
        std.debug.print("{s}Circle{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.Circle)] == pressed) green else red, reset });
        std.debug.print("{s}Share{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.Share)] == pressed) green else red, reset });
        std.debug.print("{s}Options{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.Options)] == pressed) green else red, reset });

        std.debug.print("{s}L1{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.L1)] == pressed) green else red, reset });
        std.debug.print("{s}R1{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.R1)] == pressed) green else red, reset });

        std.debug.print("{s}L2:{d}{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.L2)] != 0) green else red, self.buttons[@intFromEnum(Bindings.L2)], reset });
        std.debug.print("{s}R2:{d}{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.R2)] != 0) green else red, self.buttons[@intFromEnum(Bindings.R2)], reset });

        std.debug.print("{s}L3{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.L3)] == pressed) green else red, reset });
        std.debug.print("{s}R3{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.R3)] == pressed) green else red, reset });

        std.debug.print("      {s}up{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.DPAD_Vert)] == 0xFF) green else red, reset });
        std.debug.print("{s}left     {s}", .{ if (self.buttons[@intFromEnum(Bindings.DPAD_Hori)] == 0xFF) green else red, reset });
        std.debug.print("{s}right{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.DPAD_Hori)] == 1) green else red, reset });
        std.debug.print("     {s}down{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.DPAD_Vert)] == 1) green else red, reset });

        std.debug.print("Left Stick X:{s}{d}{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.LStick_H)] != 0) green else red, @as(i8, @bitCast(self.buttons[@intFromEnum(Bindings.LStick_H)])), reset });
        std.debug.print("Left Stick Y:{s}{d}{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.LStick_V)] != 0) green else red, @as(i8, @bitCast(self.buttons[@intFromEnum(Bindings.LStick_V)])), reset });

        std.debug.print("Right Stick X:{s}{d}{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.RStick_H)] != 0) green else red, @as(i8, @bitCast(self.buttons[@intFromEnum(Bindings.RStick_H)])), reset });
        std.debug.print("Right Stick Y:{s}{d}{s}\n", .{ if (self.buttons[@intFromEnum(Bindings.RStick_V)] != 0) green else red, @as(i8, @bitCast(self.buttons[@intFromEnum(Bindings.RStick_V)])), reset });
    }
};
