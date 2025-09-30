const std = @import("std");
const Zeren = @import("Zeren.zig");
const Zerui = @import("Zerui.zig");
const examples = @import("examples.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    _ = allocator;

    try Zeren.init();
    defer Zeren.deinit();

    var window = try Zeren.Window.createWindow(1080, 720, "Zeren", null);
    defer window.destroy();

    var tringle = try examples.Triangle.init(true);
    defer tringle.deinit();

    while (!window.shouldClose()) {
        if (window.closeWindowEvt()) break;
        window.beginFrame();
        try tringle.draw();
        window.endFrame();
    }
}
