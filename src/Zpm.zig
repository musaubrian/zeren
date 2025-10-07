const std = @import("std");
const assert = std.debug.assert;

const Pixel = struct {
    r: u8,
    g: u8,
    b: u8,
};

allocator: std.mem.Allocator,

header: struct {
    magic: []const u8,
    width: u32,
    height: u32,
    max_color_val: u8,
},

contents: std.ArrayList([]Pixel) = .empty,

pub fn init(allocator: std.mem.Allocator) Zpm {
    return Zpm{
        .allocator = allocator,
        .header = .{
            .magic = "",
            .width = 0,
            .height = 0,
            .max_color_val = 0,
        },
    };
}

pub fn loadAndParse(zpm: *Zpm, path: []const u8) !void {
    const full_path = try std.fs.cwd().realpathAlloc(zpm.allocator, path);

    var file = try std.fs.openFileAbsolute(full_path, .{ .mode = .read_only });
    defer file.close();

    const line_buf = try zpm.allocator.alloc(u8, 1 * 1024 * 1024);
    var reader = file.reader(line_buf);

    var pair_list: std.ArrayList(Pixel) = .empty;
    defer pair_list.deinit(zpm.allocator); // don't need to do this since I clear everything top level

    var pair: std.ArrayList(u8) = try .initCapacity(zpm.allocator, 3);
    defer pair.deinit(zpm.allocator); // don't need to do this since I clear everything top level

    while (reader.interface.takeDelimiterExclusive('\n')) |line| {
        if (line.len == 0 or std.mem.startsWith(u8, line, "#")) continue;

        if (zpm.header.magic.len == 0) {
            if (std.mem.eql(u8, line, "P3")) {
                std.log.info("parsing ascii ppm", .{});
                zpm.header.magic = line;
                continue;
            }

            if (std.mem.eql(u8, line, "P6")) {
                std.log.info("parsing binary ppm", .{});
                zpm.header.magic = line;
                continue;
            }
        }

        if (zpm.header.width == 0 and zpm.header.height == 0) {
            var iter = std.mem.splitScalar(u8, line, ' ');
            zpm.header.width = try std.fmt.parseInt(u32, iter.next().?, 10);
            zpm.header.height = try std.fmt.parseInt(u32, iter.next().?, 10);
            continue;
        }

        if (zpm.header.max_color_val == 0) {
            const max_color = try std.fmt.parseInt(u32, line, 10);
            assert(max_color > 0);
            assert(max_color <= 65536);
            zpm.header.max_color_val = try std.fmt.parseInt(u8, line, 10);
            continue;
        }

        if (std.mem.eql(u8, zpm.header.magic, "P6")) {
            std.log.warn("P6 format not supported yet", .{});
            break;
        }

        var pairs = std.mem.splitScalar(u8, line, ' ');

        while (pairs.next()) |it| {
            if (it.len == 0) continue;

            const pix = try std.fmt.parseInt(u8, it, 10);
            assert(pix <= zpm.header.max_color_val);

            try pair.append(zpm.allocator, pix);
            if (pair.items.len == 3) {
                const p = Pixel{
                    .r = pair.items[0],
                    .g = pair.items[1],
                    .b = pair.items[2],
                };

                try pair_list.append(zpm.allocator, p);
                pair.clearRetainingCapacity();
            }

            if (pair_list.items.len == zpm.header.width) {
                const to_append = try pair_list.clone(zpm.allocator);
                try zpm.contents.append(zpm.allocator, to_append.items);
                pair_list.clearRetainingCapacity();
            }
        }
    } else |err| if (err != error.EndOfStream) return err;
}

pub fn renderText(zpm: *Zpm) !void {
    const font = " .,:;i1tfLCG08@";
    for (zpm.contents.items) |row| {
        for (0..row.len) |idx| {
            const pixl = row[idx];
            const avg: usize = @divTrunc((@as(usize, pixl.r) + pixl.g + pixl.b), 3);
            const c = @divTrunc(avg * (font.len - 1), zpm.header.max_color_val);
            std.debug.print("\x1b[38;2;{d};{d};{d}m{c}", .{ pixl.r, pixl.g, pixl.b, font[c] });
        }
        std.debug.print("\n\x1b[0m", .{});
    }
}

///PPM parser
const Zpm = @This();
