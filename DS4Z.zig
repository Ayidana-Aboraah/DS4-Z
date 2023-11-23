const std = @import("std");

const Bindings = enum(u8) {
    Square,
    Cross,
    Circle,
    Triangle,
    L1,
    R1,

    share = 8,
    options = 9,
    L3 = 10,
    R3 = 11,
    PSN = 12,

    Touchpad_Click = 13,
    Touchpad_Touch = 14,

    Touchpad_Xaxis = 15,
    Touchpad_Yaxis = 16,

    DPAD_Hori = 17,
    DPAD_Vert = 18,

    LStick_H = 19,
    LStick_V = 20,
    RStick_H = 21,
    RStick_V = 22,

    L2 = 30,
    R2 = 31,
};

const colours = enum([]u8) {
    red = "\x1B[31m",
    green = "\x1B[32m",
    yellow = "\x1B[33m",
    blue = "\x1B[34m",
    magenta = "\x1B[35m",
    cyan = "\x1B[36m",
    white = "\x1B[37m",
    reset = "\x1B[0m",
};

const touchpad = struct { click: u8, touch: u8, coordinates: [2]u8 };

pub const Controller = struct {
    buttons: [@intFromEnum(Bindings.R2)]u8,
    in: std.fs.File,
    data: [63]u8,

    pub fn init(idx: u8) !Controller {
        var path = "/dev/input/js0".*;
        path[path.len - 1] = std.fmt.digitToChar(idx, std.fmt.Case.lower);
        return Controller{
            .buttons = [_]u8{0} ** @intFromEnum(Bindings.R2),
            .data = undefined,
            .in = try std.fs.openFileAbsolute(&path, .{}),
        };
    }

    pub fn update(self: *Controller) !void {
        var bytes_read = try self.in.read(@constCast(&self.data));
        if (bytes_read == 1) return;
        std.debug.print("Bytes Read: {d}\n", .{bytes_read});

        switch (self.data[6]) {
            1 => self.buttons[self.data[7]] = self.data[4], // most buttons
            2 => { // DPAD
                switch (self.data[7]) {
                    6, 7 => { // DPAD Horizontal & Vertical
                        self.buttons[self.data[7] + 11] = switch (std.mem.bytesAsValue(u16, self.data[4..6]).*) {
                            0x7FFF => 1, // DPAD_RIGHT & UP
                            0x8001 => 0xFF, // DPAD_LEFT & DOWN
                            else => 0,
                        };
                    },
                    3, 4 => { // L2 & R2
                        //var trig_val: u8 = self.data[5] >> 4;
                        //self.buttons[self.data[7] + 27] = trig_val;
                        // NOTES: Shifting by 4 is the same as div by 16
                        // NOTES:
                    },
                    0, 1, 2 => { // L Stick Hori & Vert + R Stick Hori
                        self.buttons[self.data[7] + 19] = self.data[5] >> 4;
                    },
                    5 => { // R Stick Vert
                        self.buttons[21] = self.data[5] >> 4;
                    },

                    9, 10 => { // Touchpad X & Y Axises
                        // self.buttons[self.data[7] + 6] = self.data[5] + (if (self.data[5] < 127) 128 else -128);
                        self.buttons[@intFromEnum(Bindings.Touchpad_Touch)] = 1;
                    },
                    11 => self.buttons[@intFromEnum(Bindings.Touchpad_Touch)] = if (self.data[4] == 1) 0 else 1,
                    else => std.debug.print("Error No Known Handle: {d}, Data Dump: {s}\n", .{ self.data[7], self.data }),
                }
            },
            else => std.debug.print("Error, Unknown Data Type: {d}, Unknown Data: {s}\n", .{ self.data[6], self.data }),
        }
    }
};
