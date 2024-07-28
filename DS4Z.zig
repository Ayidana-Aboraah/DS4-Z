const std = @import("std");

pub const Bindings = enum(u8) {
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

const pressed = 1;

// const touchpad = struct { click: u8, touch: u8, coordinates: [2]u8 };

pub const UpdateError = error{
    /// we don't know what type of data this is
    unexpected_data,
    /// We don't know how to handle the data
    unknown_handle,
};

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

    fn ax(data: u8) i8 {
        return @divTrunc(@as(i8, @bitCast(data)), 16);
    }

    pub fn update(self: *Controller) !usize {
        const bytes_read: usize = try self.in.read(@constCast(&self.data));

        if (bytes_read == 1) {
            self.updated = false;
            return bytes_read;
        }
        self.updated = true;

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

                    else => return UpdateError.unknown_handle,
                }
            },
            else => return UpdateError.unexpected_data,
        }
        return bytes_read;
    }
};
