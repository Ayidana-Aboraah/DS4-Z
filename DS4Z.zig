const std = @import("std");

const Button_Mapping = enum(u8) { Cross, Square, Triangle, Circle, Options, Share, PSN, L1, R1, L2, R2, L3, R3, DPad, Touchpad_Click, Touchpad_Touched, Touchpad_X, Touchpad_Y, LStick_X, LStick_Y, RStick_X, RStick_Y };

const Sensor_Vectors = enum(u8) {
    Gyro,
    Accel,
};

const button_map_len = @typeInfo(Button_Mapping).Enum.fields.len;
const sensor_len = @typeInfo(Button_Mapping).Enum.fields.len;
pub const Controller = struct {
    buf: [63]u8, // NOTE: Check Size may be 20, 30 or 63
    button: [button_map_len]u8,
    sensor: [sensor_len]@Vector(3, u16), // NOTE: You'll have to convert i16 for Accel Vector
    file: std.fs.File,

    pub fn init(path: []const u8) !Controller {
        return Controller{ .buf = undefined, .button = [_]u8{0} ** button_map_len, .sensor = [_]@Vector(3, u16){@Vector(3, u16){ 0, 0, 0 }} ** sensor_len, .file = try std.fs.openFileAbsolute(path, .{}) };
    }

    pub fn Update(self: *Controller) !void {
        var bytes_read = try self.file.read(@constCast(&self.buf));
        if (bytes_read == 0) return;
        std.debug.print("Bytes Read: {d}\n", .{bytes_read});

        // TEST:
        // self.buf[0] should be reportID aka usb
        self.button[@enumToInt(Button_Mapping.LStick_X)] = self.buf[1];
        self.button[@enumToInt(Button_Mapping.LStick_Y)] = self.buf[2];

        self.button[@enumToInt(Button_Mapping.RStick_X)] = self.buf[3];
        self.button[@enumToInt(Button_Mapping.RStick_Y)] = self.buf[4];

        // self.button[@enumToInt(Button_Mapping.DPad)] // TODO: Figure out how we're handling teh directions
        self.button[@enumToInt(Button_Mapping.Square)] = self.buf[5] & (1 << 4); // TODO: Check if we need to move it 3 or 4 bits forward
        self.button[@enumToInt(Button_Mapping.Cross)] = self.buf[5] & (1 << 5);
        self.button[@enumToInt(Button_Mapping.Circle)] = self.buf[5] & (1 << 6);
        self.button[@enumToInt(Button_Mapping.Triangle)] = self.buf[5] & (1 << 7);

        self.button[@enumToInt(Button_Mapping.L1)] = self.buf[6] & 1;
        self.button[@enumToInt(Button_Mapping.R1)] = self.buf[6] & (1 << 1);
        // self.button[@enumToInt(Button_Mapping.L2)] = self.buf[6] & (1 << 2);
        // self.button[@enumToInt(Button_Mapping.R2)] = self.buf[6] & (1 << 3);
        self.button[@enumToInt(Button_Mapping.Share)] = self.buf[6] & (1 << 4);
        self.button[@enumToInt(Button_Mapping.Options)] = self.buf[6] & (1 << 5);
        self.button[@enumToInt(Button_Mapping.L3)] = self.buf[6] & (1 << 6);
        self.button[@enumToInt(Button_Mapping.R3)] = self.buf[6] & (1 << 7);

        self.button[@enumToInt(Button_Mapping.PSN)] = self.buf[7] & 1;
        self.button[@enumToInt(Button_Mapping.Touchpad_Click)] = self.buf[7] & 2;
        // NOTE: The rest of byte would be a counter that's incremented per each report sent

        self.button[@enumToInt(Button_Mapping.L2)] = self.buf[8];
        self.button[@enumToInt(Button_Mapping.R2)] = self.buf[9];
        //NOTE: 12 is battery level

        self.sensor[@enumToInt(Sensor_Vectors.Gyro)] = [3]u16{ (self.buf[13] << 8) | self.buf[14], (self.buf[15] << 8) | self.buf[16], (self.buf[17] << 8) | self.buf[18] };
        self.sensor[@enumToInt(Sensor_Vectors.Accel)] = [3]u16{ (self.buf[19] << 8) | self.buf[20], (self.buf[21] << 8) | self.buf[22], (self.buf[23] << 8) | self.buf[24] };
    }

    // maybe make a different struct for this type of thing
    // pub fn UpdateWithBindings(){} // Pass in an array with callbacks for when a button is pressed
};
